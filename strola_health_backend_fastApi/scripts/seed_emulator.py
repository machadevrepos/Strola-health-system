"""One-time dev seed: populates the Firebase Auth + Firestore emulators with
the same dataset the admin/super-admin Next.js apps use as mock data, so the
real-backend-wired frontends show the same people, devices, posts, and
challenges they did on mock data. Mirrors
strola_health_super_admin_next/src/lib/data/mock-data.ts field-for-field —
if that file changes, this should change with it.

Run from the backend repo root, with the Firebase emulators already running:
    python scripts/seed_emulator.py

Every seeded user gets the same dev-only password: see SEED_PASSWORD below.
"""

import math
import sys
from datetime import date, datetime, timedelta, timezone
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from firebase_admin import auth as firebase_auth

from app.core.firebase import get_firestore
from app.core.security import disable_auth_account, set_role_claim
from app.models.activity import DailyActivitySummary, SourceMetrics, WorkoutSession
from app.models.badge import Badge, UserBadge
from app.models.challenge import Challenge, ChallengeParticipant
from app.models.community import CommunityPost, ModerationInfo
from app.models.device import Device
from app.models.enums import DataSource
from app.models.feature_flag import FeatureFlag
from app.models.report import Report
from app.models.analytics import AnalyticsEvent
from app.models.user import PrivacySettings, Subscription, UserProfile
from app.repositories.activity_repository import DailyActivitySummaryRepository, WorkoutSessionRepository
from app.repositories.analytics_repository import AnalyticsEventRepository
from app.repositories.badge_repository import BadgeRepository, UserBadgeRepository
from app.repositories.challenge_repository import ChallengeParticipantRepository, ChallengeRepository
from app.repositories.community_repository import CommunityPostRepository
from app.repositories.device_repository import DeviceRepository
from app.repositories.feature_flag_repository import FeatureFlagRepository
from app.repositories.report_repository import ReportRepository
from app.repositories.user_repository import UserRepository

SEED_PASSWORD = "StrollaDev123!"
NOW = datetime(2026, 6, 21, 9, 0, 0, tzinfo=timezone.utc)


def days_ago(n: float, hour: int = 9, minute: int = 0) -> datetime:
    # timedelta arithmetic (not .replace()) so minute/hour overflow rolls
    # forward, matching JS's setUTCHours normalization the source data relies
    # on (e.g. minute=83 becomes +1h23m, not a ValueError).
    midnight = (NOW - timedelta(days=n)).replace(hour=0, minute=0, second=0, microsecond=0)
    return midnight + timedelta(hours=hour, minutes=minute)


def date_key(n: float) -> date:
    return days_ago(n).date()


# --- Users -------------------------------------------------------------------

USER_SEEDS = [
    dict(id="usr_001", email="priya.shah@gmail.com", username="priya.walks", name="Priya Shah", location="Leeds, UK", bio="Recovering from a knee injury, taking it one walk at a time.", gender="female", height_cm=163, weight_kg=61, daily_goal_steps=6000, role="user", created_days_ago=188, subscription=dict(tier="premium", status="active", renews_at=days_ago(-9)), reasons=["accurate_tracking"]),
    dict(id="usr_002", email="tom.brennan@outlook.com", username="tombrennan", name="Tom Brennan", location="Bristol, UK", gender="male", height_cm=179, weight_kg=82, daily_goal_steps=10000, role="user", created_days_ago=142, subscription=dict(tier="free", status="trialing", comp_until=days_ago(-3), comp_reason="signup_trial")),
    dict(id="usr_003", email="sarah.mwangi@yahoo.com", username="sarah.m", name="Sarah Mwangi", location="Manchester, UK", bio="Stroller walks with a 7-month-old most mornings.", gender="female", height_cm=168, weight_kg=64, daily_goal_steps=8000, role="user", created_days_ago=96, subscription=dict(tier="premium", status="active", renews_at=days_ago(-21)), reasons=["stroller_wagon"]),
    dict(id="usr_004", email="j.kowalczyk88@gmail.com", username="jkowalczyk", name="James Kowalczyk", location="Sheffield, UK", gender="male", height_cm=174, weight_kg=76, daily_goal_steps=12000, role="user", created_days_ago=211, subscription=dict(tier="free", status="expired")),
    dict(id="usr_005", email="mei.lin.99@gmail.com", username="mei.lin", name="Mei Lin", location="Birmingham, UK", bio="Walking pad at my desk, every single day.", gender="female", height_cm=159, weight_kg=55, daily_goal_steps=9000, role="user", created_days_ago=64, subscription=dict(tier="free", status="trialing", comp_until=days_ago(-26), comp_reason="signup_trial"), reasons=["walking_pad"]),
    dict(id="usr_006", email="dan.holloway@hotmail.com", username="dan.h", name="Dan Holloway", location="Edinburgh, UK", gender="male", height_cm=183, weight_kg=88, daily_goal_steps=10000, role="user", created_days_ago=301, subscription=dict(tier="premium", status="active", renews_at=days_ago(-14))),
    dict(id="usr_007", email="alex.reyes@gmail.com", username="alex.r", name="Alex Reyes", location="Cardiff, UK", gender="other", height_cm=171, weight_kg=69, daily_goal_steps=15000, role="user", created_days_ago=47, subscription=dict(tier="premium", status="active", comp_until=days_ago(-150), comp_reason="kickstarter_backer")),
    dict(id="usr_008", email="fatima.hussain22@gmail.com", username="fatima.h", name="Fatima Hussain", location="Glasgow, UK", bio="Night-shift A&E nurse, can't wear a watch on the ward.", gender="female", height_cm=165, weight_kg=60, daily_goal_steps=7000, role="user", created_days_ago=33, subscription=dict(tier="free", status="trialing", comp_until=days_ago(-4), comp_reason="signup_trial"), reasons=["cant_wear_wearable"]),
    dict(id="usr_009", email="ollie.fenwick@gmail.com", username="ollie.fenwick", name="Ollie Fenwick", location="Newcastle, UK", gender="male", height_cm=177, weight_kg=79, daily_goal_steps=10000, role="user", created_days_ago=19, subscription=dict(tier="free", status="trialing", comp_until=days_ago(-26), comp_reason="signup_trial")),
    dict(id="usr_010", email="ruth.adeyemi@gmail.com", username="ruth.a", name="Ruth Adeyemi", location="London, UK", gender="female", height_cm=170, weight_kg=67, daily_goal_steps=8500, role="user", created_days_ago=5, subscription=dict(tier="free", status="trialing", comp_until=days_ago(-25), comp_reason="signup_trial")),
    dict(id="usr_011", email="marcus.webb@protonmail.com", username="marcus.webb", name="Marcus Webb", location="Liverpool, UK", gender="male", height_cm=181, weight_kg=91, daily_goal_steps=10000, role="user", created_days_ago=220, subscription=dict(tier="free", status="expired"), banned=True, ban_reason="Repeated harassment in community comments after two prior warnings."),
    dict(id="usr_012", email="lena.kovac@gmail.com", username="lena.k", name="Lena Kovac", location="Nottingham, UK", gender="female", height_cm=162, weight_kg=58, daily_goal_steps=9500, role="user", created_days_ago=78, subscription=dict(tier="premium", status="active", renews_at=days_ago(-2))),
    dict(id="usr_013", email="deleted-user-9f2@strolla.health", username="deleted_9f2a8b1c", name="Deleted User", gender="prefer_not_to_say", height_cm=170, weight_kg=None, daily_goal_steps=10000, role="user", created_days_ago=260, subscription=dict(tier="free", status="expired"), deleted=True),
    dict(id="usr_014", email="ben.okafor@gmail.com", username="ben.okafor", name="Ben Okafor", location="Leicester, UK", gender="male", height_cm=175, weight_kg=73, daily_goal_steps=11000, role="user", created_days_ago=13, subscription=dict(tier="free", status="trialing", comp_until=days_ago(-17), comp_reason="signup_trial")),
    dict(id="usr_015", email="grace.tan@gmail.com", username="grace.tan", name="Grace Tan", location="Southampton, UK", gender="female", height_cm=160, weight_kg=54, daily_goal_steps=7500, role="user", created_days_ago=156, subscription=dict(tier="premium", status="active", renews_at=days_ago(-30))),
    dict(id="usr_016", email="support.maya@strollahealth.com", username="maya.ops", name="Maya Whitfield", location="Remote", gender="female", height_cm=167, weight_kg=63, daily_goal_steps=8000, role="admin", created_days_ago=305, subscription=dict(tier="free", status="active")),
    dict(id="usr_017", email="founder.sarah@strollahealth.com", username="sarah.founder", name="Sarah Pemberton", location="Remote", gender="female", height_cm=165, weight_kg=60, daily_goal_steps=8000, role="super_admin", created_days_ago=365, subscription=dict(tier="free", status="active")),
    dict(id="usr_018", email="callum.ferris@gmail.com", username="callum.f", name="Callum Ferris", location="Aberdeen, UK", gender="male", height_cm=178, weight_kg=84, daily_goal_steps=10000, role="user", created_days_ago=41, subscription=dict(tier="free", status="trialing", comp_until=days_ago(-1), comp_reason="signup_trial")),
    dict(id="usr_019", email="isabel.cruz@gmail.com", username="isabel.cruz", name="Isabel Cruz", location="Coventry, UK", gender="female", height_cm=158, weight_kg=52, daily_goal_steps=6500, role="user", created_days_ago=9, subscription=dict(tier="free", status="trialing", comp_until=days_ago(-21), comp_reason="signup_trial")),
    dict(id="usr_020", email="harvey.nash@gmail.com", username="harvey.nash", name="Harvey Nash", location="Belfast, UK", gender="male", height_cm=172, weight_kg=70, daily_goal_steps=10000, role="user", created_days_ago=2, subscription=dict(tier="free", status="trialing", comp_until=days_ago(-28), comp_reason="signup_trial")),
    dict(id="usr_021", email="noah.sinclair@gmail.com", username="noah.sinclair", name="Noah Sinclair", location="York, UK", gender="male", height_cm=180, weight_kg=86, daily_goal_steps=8000, role="user", created_days_ago=6, subscription=dict(tier="free", status="expired")),
    dict(id="usr_022", email="aisha.begum@gmail.com", username="aisha.begum", name="Aisha Begum", location="Bradford, UK", gender="female", height_cm=161, weight_kg=57, daily_goal_steps=7000, role="user", created_days_ago=15, subscription=dict(tier="free", status="expired")),
    dict(id="usr_023", email="connor.walsh@gmail.com", username="connor.walsh", name="Connor Walsh", location="Derby, UK", gender="male", height_cm=176, weight_kg=80, daily_goal_steps=9000, role="user", created_days_ago=24, subscription=dict(tier="free", status="expired")),
    dict(id="usr_024", email="trust-safety.priyanka@strollahealth.com", username="priyanka.ts", name="Priyanka Rao", location="Remote", gender="female", height_cm=164, weight_kg=58, daily_goal_steps=8000, role="admin", created_days_ago=112, subscription=dict(tier="free", status="active")),
    dict(id="usr_025", email="support.danny@strollahealth.com", username="danny.ops", name="Danny Osei", location="Remote", gender="male", height_cm=180, weight_kg=77, daily_goal_steps=8000, role="admin", created_days_ago=11, subscription=dict(tier="free", status="active")),
]


def build_subscription(seed: dict) -> Subscription:
    base = dict(
        tier="free",
        status="trialing",
        comp_until=None,
        comp_reason=None,
        revenuecat_app_user_id=f"rc_{seed['id']}" if seed["subscription"].get("status") == "active" else None,
        renews_at=None,
        cancelled_at=None,
    )
    base.update(seed["subscription"])
    return Subscription.model_validate(base)


def build_user(seed: dict) -> UserProfile:
    deleted = seed.get("deleted", False)
    return UserProfile(
        id=seed["id"],
        email=None if deleted else seed["email"],
        username=seed["username"],
        name="Deleted User" if deleted else seed["name"],
        location=None if deleted else seed.get("location"),
        bio=None if deleted else seed.get("bio"),
        photo_url=None,
        height_cm=seed["height_cm"],
        gender=seed["gender"],
        date_of_birth=None if deleted else (NOW - timedelta(days=365 * (24 + (len(seed["id"]) % 12)))).date(),
        reasons=seed.get("reasons", []),
        units="metric",
        onboarding_complete=True,
        daily_goal_steps=seed["daily_goal_steps"],
        weight_kg=seed["weight_kg"],
        role=seed["role"],
        privacy=PrivacySettings(show_in_leaderboards=not seed.get("banned", False)),
        subscription=build_subscription(seed),
        banned=seed.get("banned", False),
        ban_reason=seed.get("ban_reason"),
        deleted=deleted,
        deleted_at=days_ago(40) if deleted else None,
        created_at=days_ago(seed["created_days_ago"]),
        updated_at=days_ago(min(seed["created_days_ago"], 1)),
    )


# --- Devices -------------------------------------------------------------------

DEVICE_SEEDS = [
    dict(id="dev_001", serial_number="STR-10042", ble_mac="F2:3A:91:0C:88:11", firmware_version="1.4.2", manufacturing_batch="B-2025-11", owner_user_id="usr_001", paired_at=days_ago(180), last_seen_at=days_ago(0, 7, 40), battery_level=62, created_at=days_ago(190)),
    dict(id="dev_002", serial_number="STR-10043", ble_mac="F2:3A:91:0C:88:12", firmware_version="1.4.2", manufacturing_batch="B-2025-11", owner_user_id="usr_003", paired_at=days_ago(90), last_seen_at=days_ago(0, 6, 12), battery_level=88, created_at=days_ago(190)),
    dict(id="dev_003", serial_number="STR-10044", ble_mac="F2:3A:91:0C:88:13", firmware_version="1.3.0", manufacturing_batch="B-2025-11", owner_user_id="usr_006", paired_at=days_ago(295), last_seen_at=days_ago(3, 18, 0), battery_level=14, created_at=days_ago(300)),
    dict(id="dev_004", serial_number="STR-10045", ble_mac=None, firmware_version=None, manufacturing_batch="B-2025-12", owner_user_id=None, paired_at=None, last_seen_at=None, battery_level=None, created_at=days_ago(60)),
    dict(id="dev_005", serial_number="STR-10046", ble_mac=None, firmware_version=None, manufacturing_batch="B-2025-12", owner_user_id=None, paired_at=None, last_seen_at=None, battery_level=None, created_at=days_ago(60)),
    dict(id="dev_006", serial_number="STR-10047", ble_mac="F2:3A:91:0C:88:16", firmware_version="1.4.2", manufacturing_batch="B-2025-12", owner_user_id="usr_012", paired_at=days_ago(70), last_seen_at=days_ago(0, 8, 5), battery_level=45, created_at=days_ago(75)),
    dict(id="dev_007", serial_number="STR-10048", ble_mac="F2:3A:91:0C:88:17", firmware_version="1.2.1", manufacturing_batch="B-2025-09", owner_user_id="usr_015", paired_at=days_ago(150), last_seen_at=days_ago(12, 9, 0), battery_level=3, created_at=days_ago(160)),
]


# --- Daily summaries + sessions ------------------------------------------------

def build_daily_history(user_id: str, base_steps: int, variance: int, days: int) -> list[DailyActivitySummary]:
    out = []
    for i in range(days):
        wobble = math.sin(i * 1.3 + len(user_id)) * variance + (-variance * 0.6 if i % 7 == 0 else 0)
        steps = max(800, round(base_steps + wobble))
        distance = round(steps * 0.682, 1)
        calories = round(steps * 0.041)
        out.append(
            DailyActivitySummary(
                id=f"{user_id}_{date_key(i).isoformat()}",
                user_id=user_id,
                date=date_key(i),
                by_source={DataSource.strolla_device.value: SourceMetrics(steps=steps, distance_meters=distance, calories=calories)},
                steps=steps,
                distance_meters=distance,
                calories=calories,
                primary_source=DataSource.strolla_device,
                updated_at=days_ago(i, 21, 0),
            )
        )
    return out


SESSION_SEEDS = [
    dict(id="sess_001", user_id="usr_001", start_time=days_ago(0, 7, 5), end_time=days_ago(0, 7, 38), steps=4120, distance_meters=2810.6, duration_seconds=1980, activity_type="outdoor_walk", avg_pace_sec_per_km=705, calories_burned=98, created_at=days_ago(0, 7, 38)),
    dict(id="sess_002", user_id="usr_003", start_time=days_ago(0, 6, 0), end_time=days_ago(0, 6, 41), steps=5230, distance_meters=3568.9, duration_seconds=2460, activity_type="outdoor_walk", avg_pace_sec_per_km=689, calories_burned=134, created_at=days_ago(0, 6, 41)),
    dict(id="sess_003", user_id="usr_006", start_time=days_ago(1, 18, 10), end_time=days_ago(1, 18, 52), steps=6890, distance_meters=5240.2, duration_seconds=2520, activity_type="outdoor_run", avg_pace_sec_per_km=481, calories_burned=412, created_at=days_ago(1, 18, 52)),
    dict(id="sess_004", user_id="usr_012", start_time=days_ago(2, 12, 30), end_time=days_ago(2, 13, 1), steps=0, distance_meters=0, duration_seconds=1860, activity_type="yoga", avg_pace_sec_per_km=None, calories_burned=64, created_at=days_ago(2, 13, 1)),
    dict(id="sess_005", user_id="usr_001", start_time=days_ago(3, 19, 0), end_time=days_ago(3, 19, 47), steps=3980, distance_meters=2714.0, duration_seconds=2820, activity_type="other", custom_activity_name="Garden circuits", avg_pace_sec_per_km=None, calories_burned=159, created_at=days_ago(3, 19, 47)),
]


# --- Community posts + reports --------------------------------------------------

POST_SEEDS = [
    dict(id="post_001", author_id="usr_003", content="Morning stroller walk before the school run, 5.2km and the baby's already asleep. Small wins.", days_ago=0, likes=24, comments=6, step_count=6820, image_url="https://picsum.photos/seed/strolla-park-morning/800/500"),
    dict(id="post_002", author_id="usr_007", content="Hit 70,400 steps this week, new personal best. The 10K Daily Streak challenge is brutal but it works.", days_ago=0, likes=41, comments=11, step_count=70400, badge_emoji="🔥"),
    dict(id="post_003", author_id="usr_015", content="Finally back to my pre-injury pace. 8 weeks of physio and walking pads, worth every minute.", days_ago=1, likes=58, comments=19, step_count=5320, badge_emoji="⭐"),
    dict(id="post_004", author_id="usr_006", content="Rainy Edinburgh run this morning, route through the Meadows. Strolla device didn't drop connection once.", days_ago=1, likes=19, comments=4, step_count=9120, image_url="https://picsum.photos/seed/strolla-edinburgh-run/800/500"),
    dict(id="post_005", author_id="usr_011", content="This app is a scam and everyone posting here is fake, unsubscribe before they take your money", days_ago=1, likes=2, comments=3),
    dict(id="post_006", author_id="usr_012", content="Yoga + 9k steps day. Strolla counts the steps, my knees handle the rest.", days_ago=2, likes=33, comments=8, step_count=9450),
    dict(id="post_007", author_id="usr_002", content="Week one done. Honestly didn't think I'd stick with it past day 3.", days_ago=2, likes=14, comments=2),
    dict(id="post_008", author_id="usr_008", content="Twelve hour shift, no watch allowed on the ward, Strolla in my pocket still caught 11,200 steps.", days_ago=3, likes=67, comments=15, step_count=11200, badge_emoji="🏥"),
    dict(id="post_009", author_id="usr_001", content="Someone in the comments keeps posting links to a 'free premium' site, please don't click that, report it instead.", days_ago=3, likes=22, comments=9),
    dict(id="post_010", author_id="usr_005", content="Walking pad under the standing desk, 14k steps and I never left my office. Wild.", days_ago=4, likes=29, comments=7, step_count=14080),
    dict(id="post_011", author_id="usr_018", content="DM me for a free Strolla premium code, link in bio", days_ago=4, likes=1, comments=0, hidden=dict(by="usr_016", reason="Spam / scam link in a post impersonating an official promotion.", days_ago=4)),
    dict(id="post_012", author_id="usr_009", content="First week with the tracker. Already 3,000 steps ahead of where I was on my phone alone.", days_ago=5, likes=16, comments=3, step_count=8100),
    dict(id="post_013", author_id="usr_019", content="Cardiff Bay loop, perfect evening for it.", days_ago=5, likes=21, comments=2, image_url="https://picsum.photos/seed/strolla-cardiff-bay/800/500"),
    dict(id="post_014", author_id="usr_011", content="anyone else think the leaderboard is rigged lol staff accounts always at the top", days_ago=6, likes=4, comments=6, hidden=dict(by="usr_016", reason="Unsubstantiated accusation against staff, escalating in comments. Hidden pending review.", days_ago=6)),
    dict(id="post_015", author_id="usr_014", content="Day 1. Goal is 11,000. Let's see how this goes.", days_ago=7, likes=9, comments=1),
    dict(id="post_016", author_id="usr_003", content="Two months postpartum and the stroller walks are genuinely the best part of my day.", days_ago=8, likes=71, comments=23, step_count=6200, image_url="https://picsum.photos/seed/strolla-stroller-path/800/500"),
    dict(id="post_017", author_id="usr_020", content="Just paired my device, the setup took two minutes. Impressed.", days_ago=1, likes=6, comments=1),
]

REPORT_SEEDS = [
    dict(id="rep_001", reporter_id="usr_001", target_type="post", target_id="post_011", reason="This post is advertising a fake 'free premium' link, looks like a phishing attempt.", status="resolved", resolved_by="usr_016", resolved_at=days_ago(4, 15, 0), resolution_note="Post hidden, author warned via email.", created_at=days_ago(4, 13, 30)),
    dict(id="rep_002", reporter_id="usr_007", target_type="user", target_id="usr_011", reason="Keeps leaving harassing comments on other people's step posts, this is the third time I've reported him.", status="resolved", resolved_by="usr_016", resolved_at=days_ago(2, 10, 0), resolution_note="Account banned after third confirmed incident.", created_at=days_ago(2, 9, 0)),
    dict(id="rep_003", reporter_id="usr_003", target_type="post", target_id="post_014", reason="Unfounded accusation that's stirring up the comment section, feels like it's heading toward a pile-on.", status="open", created_at=days_ago(6, 11, 20)),
    dict(id="rep_004", reporter_id="usr_012", target_type="post", target_id="post_005", reason="Calling the app a scam with no basis, discouraging other users in the thread.", status="open", created_at=days_ago(1, 16, 40)),
    dict(id="rep_005", reporter_id="usr_015", target_type="user", target_id="usr_009", reason="Profile photo looks like it might not be theirs, possible impersonation, wanted to flag just in case.", status="dismissed", resolved_by="usr_016", resolved_at=days_ago(3, 9, 0), resolution_note="Checked, no impersonation, just a stock-style profile photo. No action needed.", created_at=days_ago(4, 8, 0)),
    dict(id="rep_006", reporter_id="usr_002", target_type="post", target_id="post_011", reason="Same spam link as another report, posting again under a new comment.", status="open", created_at=days_ago(0, 9, 0)),
]


# --- Challenges + participants -------------------------------------------------

CHALLENGE_SEEDS = [
    dict(id="chal_001", title="10K Daily Streak", description="Hit 10,000 steps every day for 7 days straight.", goal_steps=70000, start_date=date_key(10), end_date=date_key(-4), badge_emoji="🔥", visibility="public", is_official=True, created_at=days_ago(11)),
    dict(id="chal_002", title="50km This Month", description="Walk or run 50 kilometres before the month ends.", goal_steps=65616, start_date=date_key(20), end_date=date_key(-9), badge_emoji="🗺️", visibility="public", created_by="usr_016", created_at=days_ago(21)),
    dict(id="chal_003", title="Weekend Warrior", description="Get 25,000 steps over Saturday and Sunday.", goal_steps=25000, start_date=date_key(4), end_date=date_key(-2), badge_emoji="⚡", visibility="public", created_by="usr_016", created_at=days_ago(5)),
    dict(id="chal_004", title="Office Walking Club", description="Private challenge for the Leeds office crew, 40k steps each over two weeks.", goal_steps=40000, start_date=date_key(13), end_date=date_key(-1), badge_emoji="🏢", visibility="private", invite_code="LDS-WALK-22", created_by="usr_001", created_at=days_ago(14)),
    dict(id="chal_005", title="May Step Sprint", description="Last month's official challenge, archived for reference.", goal_steps=60000, start_date=date(2026, 5, 1), end_date=date(2026, 5, 31), badge_emoji="🏆", visibility="public", created_at=datetime(2026, 4, 29, 9, 0, 0, tzinfo=timezone.utc)),
]


def participant(challenge_id: str, user_id: str, steps: int, locked_goal: int, joined_days_ago: float, left: float | None = None) -> ChallengeParticipant:
    return ChallengeParticipant(
        id=f"{challenge_id}_{user_id}",
        challenge_id=challenge_id,
        user_id=user_id,
        steps=steps,
        locked_daily_goal=locked_goal,
        joined_at=days_ago(joined_days_ago),
        left_at=days_ago(left) if left is not None else None,
    )


PARTICIPANT_SEEDS = [
    ("chal_001", "usr_007", 42100, 15000, 10, None),
    ("chal_001", "usr_006", 38500, 10000, 10, None),
    ("chal_001", "usr_001", 31200, 6000, 10, None),
    ("chal_001", "usr_003", 28900, 8000, 9, None),
    ("chal_001", "usr_015", 21000, 7500, 9, None),
    ("chal_001", "usr_011", 9400, 10000, 9, 6),
    ("chal_002", "usr_002", 52400, 10000, 20, None),
    ("chal_002", "usr_009", 48900, 10000, 19, None),
    ("chal_002", "usr_005", 41200, 9000, 18, None),
    ("chal_003", "usr_006", 22800, 10000, 4, None),
    ("chal_003", "usr_001", 14300, 6000, 4, None),
    ("chal_003", "usr_012", 12100, 9500, 3, None),
    ("chal_004", "usr_001", 31200, 6000, 13, None),
    ("chal_004", "usr_004", 24800, 12000, 13, None),
]


# --- Badges + feature flags -----------------------------------------------------

BADGE_SEEDS = [
    dict(id="badge_001", name="First Steps", description="Completed onboarding and logged your first day of steps.", emoji="👟", created_at=days_ago(300)),
    dict(id="badge_002", name="Early Bird", description="Logged a walk before 7am, five times.", emoji="🌅", created_at=days_ago(280)),
    dict(id="badge_003", name="Streak Master", description="Hit your daily goal 30 days in a row.", emoji="🔥", created_at=days_ago(260)),
    dict(id="badge_004", name="Marathon Mile", description="Walked or ran a cumulative 42.2km in a single week.", emoji="🏃", created_at=days_ago(240)),
    dict(id="badge_005", name="Community Champion", description="Posted 25 times and helped others stay motivated.", emoji="💬", created_at=days_ago(200)),
    dict(id="badge_006", name="Founding Walker", description="Joined during the Kickstarter launch window.", emoji="🚀", created_at=days_ago(360)),
]

USER_BADGE_SEEDS = [
    dict(id="usr_001_badge_001", user_id="usr_001", badge_id="badge_001", awarded_at=days_ago(187)),
    dict(id="usr_001_badge_003", user_id="usr_001", badge_id="badge_003", awarded_at=days_ago(60)),
    dict(id="usr_006_badge_001", user_id="usr_006", badge_id="badge_001", awarded_at=days_ago(300)),
    dict(id="usr_006_badge_004", user_id="usr_006", badge_id="badge_004", awarded_at=days_ago(40)),
    dict(id="usr_006_badge_006", user_id="usr_006", badge_id="badge_006", awarded_at=days_ago(295), awarded_by="usr_017"),
    dict(id="usr_007_badge_006", user_id="usr_007", badge_id="badge_006", awarded_at=days_ago(46), awarded_by="usr_017"),
    dict(id="usr_003_badge_002", user_id="usr_003", badge_id="badge_002", awarded_at=days_ago(50)),
    dict(id="usr_003_badge_005", user_id="usr_003", badge_id="badge_005", awarded_at=days_ago(12), awarded_by="usr_016"),
]

FEATURE_FLAG_SEEDS = [
    dict(key="widget", required_tier="premium", description="Home/lock screen step widget.", updated_at=days_ago(40)),
    dict(key="challenges", required_tier="free", description="Join public step challenges.", updated_at=days_ago(40)),
    dict(key="private_challenges", required_tier="premium", description="Create invite-only challenges.", updated_at=days_ago(40)),
    dict(key="activity_insights", required_tier="premium", description="Extra stats tabs beyond the overview.", updated_at=days_ago(40)),
    dict(key="extra_stats_tabs", required_tier="premium", description="Day/week/month breakdown views.", updated_at=days_ago(40)),
]


# --- Analytics events (30-day synthetic series for charts) --------------------

def pick(arr: list, seed: int):
    return arr[seed % len(arr)]


def build_analytics_events() -> list[AnalyticsEvent]:
    events: list[AnalyticsEvent] = []
    counter = 0
    active_user_pool = [s["id"] for s in USER_SEEDS if s["role"] == "user" and not s.get("deleted")]

    def add(event_type: str, user_id: str, created_at: datetime, metadata: dict | None = None) -> None:
        nonlocal counter
        events.append(AnalyticsEvent(id=f"evt_{counter}", event_type=event_type, user_id=user_id, metadata=metadata or {}, created_at=created_at))
        counter += 1

    for day in range(29, -1, -1):
        weekday = (day + 3) % 7
        weekend_dip = 0.78 if weekday in (0, 6) else 1
        trend = 1 + (29 - day) * 0.01
        base_dau = round(11 * weekend_dip * trend)

        opened_by: list[str] = []
        seen = set()
        for i in range(base_dau):
            user_id = pick(active_user_pool, counter * 7 + i + day)
            if user_id not in seen:
                seen.add(user_id)
                opened_by.append(user_id)
        for user_id in opened_by:
            add("app_opened", user_id, days_ago(day, 8 + (counter % 12), counter % 60))

        started_count = max(1, round(len(opened_by) * 0.55))
        started_users = opened_by[:started_count]
        for user_id in started_users:
            add("workout_started", user_id, days_ago(day, 7, counter % 60))
        completed_users = started_users[: round(len(started_users) * 0.82)]
        for user_id in completed_users:
            add("workout_completed", user_id, days_ago(day, 7, (counter % 60) + 20), metadata={"steps": 3000 + (counter % 9) * 700})

        if day % 4 == 0:
            add("account_created", pick(active_user_pool, counter), days_ago(day, 11, 0))
        if day % 6 == 0:
            add("tracker_paired", pick(active_user_pool, counter + 3), days_ago(day, 12, 0))
        if day % 3 == 0:
            add("community_post_created", pick(active_user_pool, counter + 5), days_ago(day, 14, 0))
        if day % 5 == 0:
            add("challenge_joined", pick(active_user_pool, counter + 8), days_ago(day, 15, 0))
        if day % 9 == 0:
            add("challenge_completed", pick(active_user_pool, counter + 11), days_ago(day, 16, 0))
        if day % 7 == 1:
            add("premium_started", pick(active_user_pool, counter + 13), days_ago(day, 17, 0))
        if day % 11 == 2:
            add("premium_cancelled", pick(active_user_pool, counter + 17), days_ago(day, 18, 0))
        if day % 4 == 2:
            add("widget_enabled", pick(active_user_pool, counter + 19), days_ago(day, 19, 0))
        if day % 8 == 3:
            add("health_app_connected", pick(active_user_pool, counter + 23), days_ago(day, 20, 0), metadata={"provider": pick(["healthkit", "health_connect"], day)})
        if day % 6 == 4:
            add("steps_shared", pick(active_user_pool, counter + 29), days_ago(day, 21, 0))

    return events


def seed_auth_users() -> None:
    print(f"Seeding {len(USER_SEEDS)} Firebase Auth users (password: {SEED_PASSWORD})...")
    for seed in USER_SEEDS:
        try:
            firebase_auth.create_user(
                uid=seed["id"],
                email=seed["email"],
                password=SEED_PASSWORD,
                display_name=seed["name"],
                email_verified=True,
            )
        except (firebase_auth.EmailAlreadyExistsError, firebase_auth.UidAlreadyExistsError):
            pass  # re-running the seed script is idempotent
        set_role_claim(seed["id"], seed["role"])
        if seed.get("deleted"):
            disable_auth_account(seed["id"])
    print("Auth users done.")


def main() -> None:
    db = get_firestore()

    seed_auth_users()

    users = UserRepository(db)
    for seed in USER_SEEDS:
        users.upsert(seed["id"], build_user(seed))
    print(f"Seeded {len(USER_SEEDS)} user profiles.")

    devices = DeviceRepository(db)
    for seed in DEVICE_SEEDS:
        devices.upsert(seed["id"], Device(device_type="strolla_nrf7002", **seed))
    print(f"Seeded {len(DEVICE_SEEDS)} devices.")

    daily = DailyActivitySummaryRepository(db)
    history_specs = [("usr_001", 7400, 1800, 30), ("usr_003", 9200, 2200, 30), ("usr_006", 11400, 2600, 30), ("usr_012", 8800, 1500, 30)]
    count = 0
    for user_id, base, variance, days in history_specs:
        for summary in build_daily_history(user_id, base, variance, days):
            daily.upsert(summary.id, summary)
            count += 1
    print(f"Seeded {count} daily activity summaries.")

    sessions = WorkoutSessionRepository(db)
    for seed in SESSION_SEEDS:
        sessions.upsert(seed["id"], WorkoutSession(source=DataSource.strolla_app, route_points=[], **seed))
    print(f"Seeded {len(SESSION_SEEDS)} workout sessions.")

    posts = CommunityPostRepository(db)
    for seed in POST_SEEDS:
        hidden = seed.get("hidden")
        moderation = (
            ModerationInfo(hidden=True, hidden_by=hidden["by"], hidden_reason=hidden["reason"], hidden_at=days_ago(hidden["days_ago"], 14, 0))
            if hidden
            else ModerationInfo()
        )
        posts.upsert(
            seed["id"],
            CommunityPost(
                id=seed["id"],
                author_id=seed["author_id"],
                content=seed["content"],
                timestamp=days_ago(seed["days_ago"], 8 + (len(seed["id"]) % 10), 15),
                likes_count=seed["likes"],
                comments_count=seed["comments"],
                step_count=seed.get("step_count"),
                badge_emoji=seed.get("badge_emoji"),
                image_url=seed.get("image_url"),
                moderation=moderation,
            ),
        )
    print(f"Seeded {len(POST_SEEDS)} community posts.")

    reports = ReportRepository(db)
    for seed in REPORT_SEEDS:
        reports.upsert(seed["id"], Report(**seed))
    print(f"Seeded {len(REPORT_SEEDS)} reports.")

    challenges = ChallengeRepository(db)
    for seed in CHALLENGE_SEEDS:
        challenges.upsert(seed["id"], Challenge(**seed))
    print(f"Seeded {len(CHALLENGE_SEEDS)} challenges.")

    participants = ChallengeParticipantRepository(db)
    for challenge_id, user_id, steps, locked_goal, joined, left in PARTICIPANT_SEEDS:
        p = participant(challenge_id, user_id, steps, locked_goal, joined, left)
        participants.upsert(p.id, p)
    print(f"Seeded {len(PARTICIPANT_SEEDS)} challenge participants.")

    badges = BadgeRepository(db)
    for seed in BADGE_SEEDS:
        badges.upsert(seed["id"], Badge(**seed))
    print(f"Seeded {len(BADGE_SEEDS)} badges.")

    user_badges = UserBadgeRepository(db)
    for seed in USER_BADGE_SEEDS:
        user_badges.upsert(seed["id"], UserBadge(**seed))
    print(f"Seeded {len(USER_BADGE_SEEDS)} user badge awards.")

    flags = FeatureFlagRepository(db)
    for seed in FEATURE_FLAG_SEEDS:
        flags.upsert(seed["key"], FeatureFlag(**seed))
    print(f"Seeded {len(FEATURE_FLAG_SEEDS)} feature flags.")

    analytics_events = AnalyticsEventRepository(db)
    events = build_analytics_events()
    for event in events:
        analytics_events.upsert(event.id, event)
    print(f"Seeded {len(events)} analytics events.")

    print("\nDone. Every seeded account's password is:", SEED_PASSWORD)
    print("Staff logins: support.maya@strollahealth.com (admin), founder.sarah@strollahealth.com (super_admin)")


if __name__ == "__main__":
    main()
