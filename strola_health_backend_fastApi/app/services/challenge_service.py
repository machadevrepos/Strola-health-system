import uuid
from datetime import date, timedelta

from app.core.exceptions import ConflictError, NotFoundError
from app.core.time import utcnow
from app.models.analytics import AnalyticsEventType
from app.models.challenge import Challenge, ChallengeCreate, ChallengeParticipant, ChallengeUpdate
from app.models.user import UserProfile
from app.repositories.activity_repository import DailyActivitySummaryRepository
from app.repositories.challenge_repository import ChallengeParticipantRepository, ChallengeRepository
from app.services.analytics_service import AnalyticsService


class ChallengeService:
    def __init__(
        self,
        challenge_repo: ChallengeRepository,
        participant_repo: ChallengeParticipantRepository,
        daily_repo: DailyActivitySummaryRepository,
        analytics: AnalyticsService,
    ):
        self._challenges = challenge_repo
        self._participants = participant_repo
        self._daily = daily_repo
        self._analytics = analytics

    def create(
        self, payload: ChallengeCreate, *, created_by: str | None = None, is_official: bool = False
    ) -> Challenge:
        challenge = Challenge(
            id=str(uuid.uuid4()),
            title=payload.title,
            description=payload.description,
            goal_steps=payload.goal_steps,
            start_date=payload.start_date,
            end_date=payload.end_date,
            badge_emoji=payload.badge_emoji,
            accent_color_value=payload.accent_color_value,
            visibility=payload.visibility,
            is_official=is_official,
            created_by=created_by,
            created_at=utcnow(),
        )
        return self._challenges.upsert(challenge.id, challenge)

    def list_public(self, *, limit: int = 50) -> list[Challenge]:
        return self._challenges.list_public(limit=limit)

    def list_all(self, *, limit: int = 200) -> list[Challenge]:
        return self._challenges.list_all(limit=limit)

    def get(self, challenge_id: str) -> Challenge | None:
        return self._challenges.get(challenge_id)

    def update(self, challenge_id: str, payload: ChallengeUpdate) -> Challenge:
        if not self._challenges.get(challenge_id):
            raise NotFoundError("Challenge not found")
        updates = payload.model_dump(exclude_unset=True)
        if updates:
            self._challenges.update(challenge_id, updates)
        return self._challenges.get(challenge_id)

    def delete(self, challenge_id: str) -> None:
        """Cascades to participants — a deleted challenge shouldn't leave
        orphaned participant rows a leaderboard query might still surface."""
        if not self._challenges.get(challenge_id):
            raise NotFoundError("Challenge not found")
        for participant in self._participants.list_for_challenge(challenge_id, limit=10_000):
            self._participants.delete(participant.id)
        self._challenges.delete(challenge_id)

    def remove_participant(self, challenge_id: str, user_id: str) -> None:
        """Admin-forced removal (e.g. a cheater) — distinct from `leave`,
        which is the participant's own self-service exit and only soft-marks
        `left_at`. This hard-deletes the participant row entirely."""
        participant = self._participants.get_participant(challenge_id, user_id)
        if not participant:
            raise NotFoundError("Not a participant in this challenge")
        self._participants.delete(participant.id)

    def join(self, user_id: str, challenge_id: str, profile: UserProfile) -> ChallengeParticipant:
        if not self._challenges.get(challenge_id):
            raise NotFoundError("Challenge not found")
        existing = self._participants.get_participant(challenge_id, user_id)
        if existing and existing.is_active:
            raise ConflictError("Already joined this challenge")

        participant = ChallengeParticipant(
            id=self._participants.doc_id(challenge_id, user_id),
            challenge_id=challenge_id,
            user_id=user_id,
            # Snapshot now, per the client's requirement — a later change to
            # the user's personal goal must not retroactively shift this.
            locked_daily_goal=profile.daily_goal_steps,
            joined_at=utcnow(),
        )
        self._participants.upsert(participant.id, participant)
        self._analytics.track(
            AnalyticsEventType.challenge_joined, user_id=user_id, metadata={"challenge_id": challenge_id}
        )
        return participant

    def leave(self, user_id: str, challenge_id: str) -> None:
        participant = self._participants.get_participant(challenge_id, user_id)
        if not participant or not participant.is_active:
            raise NotFoundError("Not an active participant in this challenge")
        self._participants.update(participant.id, {"left_at": utcnow()})

    def leaderboard(self, challenge_id: str, *, limit: int = 200) -> list[ChallengeParticipant]:
        return self._participants.list_for_challenge(challenge_id, limit=limit)

    def list_for_user(self, user_id: str) -> list[ChallengeParticipant]:
        return self._participants.list_for_user(user_id)

    def set_official_monthly(self, challenge_id: str) -> None:
        """Super-admin: only one challenge is the official public monthly
        challenge at a time — clear the previous one first."""
        if not self._challenges.get(challenge_id):
            raise NotFoundError("Challenge not found")
        current = self._challenges.get_official()
        if current and current.id != challenge_id:
            self._challenges.update(current.id, {"is_official": False})
        self._challenges.update(challenge_id, {"is_official": True})

    def sync_user_progress(self, user_id: str, changed_day: date) -> None:
        """Called by `ActivityService` whenever a day's step total changes.
        Recomputes cumulative steps for any active challenge covering that
        day, by re-summing daily totals across the challenge's window —
        simple and correct at today's scale. If challenge windows or write
        volume grow large enough for this to be a measurable cost, revisit
        with an incremental counter or a Firestore-trigger Cloud Function
        instead of resumming on every write.
        """
        for participant in self._participants.list_for_user(user_id):
            if not participant.is_active:
                continue
            challenge = self._challenges.get(participant.challenge_id)
            if not challenge or not (challenge.start_date <= changed_day <= challenge.end_date):
                continue

            total = self._sum_steps_in_window(user_id, challenge.start_date, min(date.today(), challenge.end_date))
            if total == participant.steps:
                continue
            self._participants.update(participant.id, {"steps": total})
            if total >= challenge.goal_steps and participant.steps < challenge.goal_steps:
                self._analytics.track(
                    AnalyticsEventType.challenge_completed,
                    user_id=user_id,
                    metadata={"challenge_id": challenge.id},
                )

    def _sum_steps_in_window(self, user_id: str, start: date, end: date) -> int:
        total = 0
        day = start
        while day <= end:
            summary = self._daily.get_for_day(user_id, day)
            if summary:
                total += summary.steps
            day += timedelta(days=1)
        return total
