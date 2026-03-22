-- Schema dump from DATABASE_URL (backend/.env)
-- Generated: 2026-03-14T13:35:34.276Z

CREATE TABLE IF NOT EXISTS "audio_guides" (
  "id" UUID DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
  "place_id" VARCHAR(50),
  "tour_id" VARCHAR(50),
  "language" VARCHAR(10) DEFAULT 'en'::character varying NOT NULL,
  "audio_url" VARCHAR(500) NOT NULL,
  "duration_seconds" INTEGER,
  "title" VARCHAR(200),
  "created_at" TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS "badges" (
  "id" UUID DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
  "name" VARCHAR(100) NOT NULL,
  "icon" VARCHAR(50),
  "description" TEXT,
  "criteria" VARCHAR(100)
);

CREATE TABLE IF NOT EXISTS "bookings" (
  "id" UUID DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
  "user_id" UUID NOT NULL,
  "place_id" VARCHAR(50),
  "tour_id" VARCHAR(50),
  "booking_type" VARCHAR(20) NOT NULL,
  "booking_date" DATE NOT NULL,
  "time_slot" VARCHAR(50),
  "party_size" INTEGER DEFAULT 1,
  "status" VARCHAR(20) DEFAULT 'pending'::character varying,
  "notes" TEXT,
  "created_at" TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS "categories" (
  "id" VARCHAR(50) NOT NULL PRIMARY KEY,
  "name" VARCHAR(100) NOT NULL,
  "icon" VARCHAR(50) NOT NULL,
  "description" TEXT,
  "tags" JSONB DEFAULT '[]'::jsonb,
  "count" INTEGER DEFAULT 0,
  "color" VARCHAR(20)
);

CREATE TABLE IF NOT EXISTS "category_translations" (
  "category_id" VARCHAR(50) NOT NULL,
  "lang" VARCHAR(5) NOT NULL,
  "name" VARCHAR(100),
  "description" TEXT,
  "tags" JSONB,
  PRIMARY KEY ("category_id", "lang")
);

CREATE TABLE IF NOT EXISTS "check_ins" (
  "id" UUID DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
  "user_id" UUID NOT NULL,
  "place_id" VARCHAR(50) NOT NULL,
  "checked_at" TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS "coupon_redemptions" (
  "id" UUID DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
  "user_id" UUID NOT NULL,
  "coupon_id" UUID NOT NULL,
  "redeemed_at" TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS "coupons" (
  "id" UUID DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
  "code" VARCHAR(32) NOT NULL,
  "discount_type" VARCHAR(20) NOT NULL,
  "discount_value" NUMERIC(10,2) NOT NULL,
  "min_purchase" NUMERIC(10,2) DEFAULT 0,
  "valid_from" TIMESTAMPTZ DEFAULT now(),
  "valid_until" TIMESTAMPTZ NOT NULL,
  "usage_limit" INTEGER,
  "place_id" VARCHAR(50),
  "tour_id" VARCHAR(50),
  "event_id" VARCHAR(50),
  "created_at" TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS "email_verification_tokens" (
  "id" UUID DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
  "user_id" UUID NOT NULL,
  "token_hash" VARCHAR(64) NOT NULL,
  "expires_at" TIMESTAMPTZ NOT NULL,
  "used_at" TIMESTAMPTZ,
  "created_at" TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS "event_translations" (
  "event_id" VARCHAR(50) NOT NULL,
  "lang" VARCHAR(5) NOT NULL,
  "name" VARCHAR(255),
  "description" TEXT,
  "location" VARCHAR(255),
  "category" VARCHAR(100),
  "organizer" VARCHAR(255),
  "price_display" VARCHAR(50),
  "status" VARCHAR(50),
  PRIMARY KEY ("event_id", "lang")
);

CREATE TABLE IF NOT EXISTS "events" (
  "id" VARCHAR(50) NOT NULL PRIMARY KEY,
  "name" VARCHAR(255) NOT NULL,
  "description" TEXT NOT NULL,
  "start_date" TIMESTAMPTZ NOT NULL,
  "end_date" TIMESTAMPTZ NOT NULL,
  "location" VARCHAR(255) NOT NULL,
  "image" VARCHAR(500),
  "category" VARCHAR(100) NOT NULL,
  "organizer" VARCHAR(255),
  "price" DOUBLE PRECISION,
  "price_display" VARCHAR(50),
  "status" VARCHAR(50),
  "place_id" VARCHAR(50)
);

CREATE TABLE IF NOT EXISTS "feed_comments" (
  "id" UUID DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
  "post_id" UUID NOT NULL,
  "user_id" UUID NOT NULL,
  "author_name" VARCHAR(255) NOT NULL,
  "body" TEXT NOT NULL,
  "created_at" TIMESTAMPTZ DEFAULT now(),
  "parent_comment_id" UUID,
  "updated_at" TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS "feed_comment_likes" (
  "comment_id" UUID NOT NULL,
  "user_id" UUID NOT NULL,
  "created_at" TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY ("comment_id", "user_id")
);

CREATE TABLE IF NOT EXISTS "feed_likes" (
  "post_id" UUID NOT NULL,
  "user_id" UUID NOT NULL,
  "created_at" TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY ("post_id", "user_id")
);

CREATE TABLE IF NOT EXISTS "feed_posts" (
  "id" UUID DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
  "user_id" UUID,
  "author_name" VARCHAR(255) NOT NULL,
  "place_id" VARCHAR(50),
  "caption" TEXT,
  "image_url" VARCHAR(500),
  "video_url" VARCHAR(500),
  "type" VARCHAR(20) DEFAULT 'image'::character varying,
  "created_at" TIMESTAMPTZ DEFAULT now(),
  "author_role" VARCHAR(20) DEFAULT 'regular'::character varying,
  "hide_likes" BOOLEAN DEFAULT false,
  "comments_disabled" BOOLEAN DEFAULT false
);

CREATE TABLE IF NOT EXISTS "feed_reports" (
  "id" UUID DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
  "post_id" UUID NOT NULL,
  "user_id" UUID NOT NULL,
  "reason" VARCHAR(50),
  "created_at" TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS "feed_saves" (
  "post_id" UUID NOT NULL,
  "user_id" UUID NOT NULL,
  "created_at" TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY ("post_id", "user_id")
);

CREATE TABLE IF NOT EXISTS "interest_translations" (
  "interest_id" VARCHAR(50) NOT NULL,
  "lang" VARCHAR(5) NOT NULL,
  "name" VARCHAR(100),
  "description" TEXT,
  "tags" JSONB,
  PRIMARY KEY ("interest_id", "lang")
);

CREATE TABLE IF NOT EXISTS "interests" (
  "id" VARCHAR(50) NOT NULL PRIMARY KEY,
  "name" VARCHAR(100) NOT NULL,
  "icon" VARCHAR(50) NOT NULL,
  "description" TEXT,
  "color" VARCHAR(20) NOT NULL,
  "count" INTEGER DEFAULT 0,
  "popularity" INTEGER DEFAULT 0,
  "tags" JSONB DEFAULT '[]'::jsonb
);

CREATE TABLE IF NOT EXISTS "offer_proposals" (
  "id" UUID DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
  "user_id" UUID NOT NULL,
  "place_id" VARCHAR(50) NOT NULL,
  "message" TEXT NOT NULL,
  "suggested_discount_type" VARCHAR(20),
  "suggested_discount_value" NUMERIC(10,2),
  "status" VARCHAR(20) DEFAULT 'pending'::character varying,
  "created_at" TIMESTAMPTZ DEFAULT now(),
  "phone" VARCHAR(30),
  "restaurant_response" TEXT,
  "restaurant_responded_at" TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS "password_reset_tokens" (
  "id" UUID DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
  "user_id" UUID NOT NULL,
  "token_hash" VARCHAR(64) NOT NULL,
  "expires_at" TIMESTAMPTZ NOT NULL,
  "used_at" TIMESTAMPTZ,
  "created_at" TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS "phone_otp_codes" (
  "id" UUID DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
  "phone" VARCHAR(20) NOT NULL,
  "code_hash" VARCHAR(64) NOT NULL,
  "expires_at" TIMESTAMPTZ NOT NULL,
  "attempts" INTEGER DEFAULT 0,
  "created_at" TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS "place_offers" (
  "id" UUID DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
  "place_id" VARCHAR(50) NOT NULL,
  "title" VARCHAR(200) NOT NULL,
  "description" TEXT,
  "discount_type" VARCHAR(20) NOT NULL,
  "discount_value" NUMERIC(10,2),
  "valid_days" ARRAY,
  "start_time" TIME,
  "end_time" TIME,
  "expires_at" TIMESTAMPTZ NOT NULL,
  "created_at" TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS "place_owners" (
  "user_id" UUID NOT NULL,
  "place_id" VARCHAR(50) NOT NULL,
  PRIMARY KEY ("user_id", "place_id")
);

CREATE TABLE IF NOT EXISTS "place_reviews" (
  "id" BIGINT DEFAULT nextval('place_reviews_id_seq'::regclass) NOT NULL PRIMARY KEY,
  "place_id" VARCHAR(50) NOT NULL,
  "user_id" UUID NOT NULL,
  "rating" INTEGER NOT NULL,
  "title" TEXT,
  "review" TEXT,
  "visit_date" DATE,
  "created_at" TIMESTAMPTZ DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS "place_translations" (
  "place_id" VARCHAR(50) NOT NULL,
  "lang" VARCHAR(5) NOT NULL,
  "name" VARCHAR(255),
  "description" TEXT,
  "location" VARCHAR(255),
  "category" VARCHAR(100),
  "duration" VARCHAR(50),
  "price" VARCHAR(50),
  "best_time" VARCHAR(100),
  "tags" JSONB,
  PRIMARY KEY ("place_id", "lang")
);

CREATE TABLE IF NOT EXISTS "places" (
  "id" VARCHAR(50) NOT NULL PRIMARY KEY,
  "name" VARCHAR(255) NOT NULL,
  "description" TEXT,
  "location" VARCHAR(255),
  "latitude" DOUBLE PRECISION,
  "longitude" DOUBLE PRECISION,
  "search_name" VARCHAR(255),
  "images" JSONB DEFAULT '[]'::jsonb,
  "category" VARCHAR(100),
  "category_id" VARCHAR(50),
  "duration" VARCHAR(50),
  "price" VARCHAR(50),
  "best_time" VARCHAR(100),
  "rating" DOUBLE PRECISION,
  "review_count" INTEGER,
  "hours" JSONB,
  "tags" JSONB
);

CREATE TABLE IF NOT EXISTS "profiles" (
  "user_id" UUID NOT NULL PRIMARY KEY,
  "username" VARCHAR(100),
  "city" VARCHAR(255),
  "bio" TEXT,
  "mood" VARCHAR(50) DEFAULT 'mixed'::character varying,
  "pace" VARCHAR(50) DEFAULT 'normal'::character varying,
  "analytics" BOOLEAN DEFAULT true,
  "show_tips" BOOLEAN DEFAULT true,
  "app_rating" INTEGER DEFAULT 0,
  "updated_at" TIMESTAMPTZ DEFAULT now(),
  "onboarding_completed" BOOLEAN DEFAULT false,
  "onboarding_completed_at" TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS "saved_events" (
  "user_id" UUID NOT NULL,
  "event_id" VARCHAR(50) NOT NULL,
  PRIMARY KEY ("user_id", "event_id")
);

CREATE TABLE IF NOT EXISTS "saved_places" (
  "user_id" UUID NOT NULL,
  "place_id" VARCHAR(50) NOT NULL,
  PRIMARY KEY ("user_id", "place_id")
);

CREATE TABLE IF NOT EXISTS "saved_tours" (
  "user_id" UUID NOT NULL,
  "tour_id" VARCHAR(50) NOT NULL,
  PRIMARY KEY ("user_id", "tour_id")
);

CREATE TABLE IF NOT EXISTS "tour_translations" (
  "tour_id" VARCHAR(50) NOT NULL,
  "lang" VARCHAR(5) NOT NULL,
  "name" VARCHAR(255),
  "description" TEXT,
  "difficulty" VARCHAR(50),
  "badge" VARCHAR(50),
  "duration" VARCHAR(50),
  "price_display" VARCHAR(50),
  "includes" JSONB,
  "excludes" JSONB,
  "highlights" JSONB,
  "itinerary" JSONB,
  PRIMARY KEY ("tour_id", "lang")
);

CREATE TABLE IF NOT EXISTS "tours" (
  "id" VARCHAR(50) NOT NULL PRIMARY KEY,
  "name" VARCHAR(255) NOT NULL,
  "duration" VARCHAR(50) NOT NULL,
  "duration_hours" INTEGER NOT NULL,
  "locations" INTEGER NOT NULL,
  "rating" DOUBLE PRECISION NOT NULL,
  "reviews" INTEGER NOT NULL,
  "price" DOUBLE PRECISION NOT NULL,
  "currency" VARCHAR(10) NOT NULL,
  "price_display" VARCHAR(50) NOT NULL,
  "badge" VARCHAR(50),
  "badge_color" VARCHAR(20),
  "description" TEXT NOT NULL,
  "image" VARCHAR(500) NOT NULL,
  "difficulty" VARCHAR(50) NOT NULL,
  "languages" JSONB DEFAULT '[]'::jsonb,
  "includes" JSONB DEFAULT '[]'::jsonb,
  "excludes" JSONB DEFAULT '[]'::jsonb,
  "highlights" JSONB DEFAULT '[]'::jsonb,
  "itinerary" JSONB DEFAULT '[]'::jsonb,
  "place_ids" JSONB DEFAULT '[]'::jsonb
);

CREATE TABLE IF NOT EXISTS "translation_overrides" (
  "id" VARCHAR(100) NOT NULL PRIMARY KEY,
  "data" JSONB DEFAULT '{}'::jsonb NOT NULL,
  "updated_at" TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS "trip_shares" (
  "id" UUID DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
  "trip_id" VARCHAR(50) NOT NULL,
  "share_token" VARCHAR(64) NOT NULL,
  "expires_at" TIMESTAMPTZ,
  "can_edit" BOOLEAN DEFAULT false,
  "created_at" TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS "trips" (
  "id" VARCHAR(50) NOT NULL PRIMARY KEY,
  "user_id" UUID NOT NULL,
  "name" VARCHAR(255) NOT NULL,
  "start_date" DATE NOT NULL,
  "end_date" DATE NOT NULL,
  "description" TEXT,
  "days" JSONB DEFAULT '[]'::jsonb,
  "created_at" TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS "user_badges" (
  "user_id" UUID NOT NULL,
  "badge_id" UUID NOT NULL,
  "earned_at" TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY ("user_id", "badge_id")
);

CREATE TABLE IF NOT EXISTS "users" (
  "id" UUID DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
  "email" VARCHAR(255) NOT NULL,
  "password_hash" VARCHAR(255),
  "name" VARCHAR(255),
  "created_at" TIMESTAMPTZ DEFAULT now(),
  "auth_provider" VARCHAR(50) DEFAULT 'email'::character varying,
  "auth_provider_id" VARCHAR(255),
  "email_verified" BOOLEAN DEFAULT false,
  "phone_verified" BOOLEAN DEFAULT false,
  "is_admin" BOOLEAN DEFAULT false,
  "is_business_owner" BOOLEAN DEFAULT false,
  "avatar_url" TEXT
);

-- Performance Indexes (Feed speeds & Data loads)
CREATE INDEX IF NOT EXISTS idx_feed_posts_created_at_id ON feed_posts (created_at DESC, id DESC);
CREATE INDEX IF NOT EXISTS idx_feed_posts_place_id ON feed_posts (place_id);
CREATE INDEX IF NOT EXISTS idx_feed_likes_post_id ON feed_likes (post_id);
CREATE INDEX IF NOT EXISTS idx_feed_comments_post_id ON feed_comments (post_id);
CREATE INDEX IF NOT EXISTS idx_feed_saves_user_id ON feed_saves (user_id);

CREATE INDEX IF NOT EXISTS idx_places_rating ON places (rating DESC NULLS LAST);
CREATE INDEX IF NOT EXISTS idx_places_category ON places (category);

CREATE INDEX IF NOT EXISTS idx_tours_rating ON tours (rating DESC NULLS LAST);
CREATE INDEX IF NOT EXISTS idx_events_start_date ON events (start_date DESC);

CREATE INDEX IF NOT EXISTS idx_place_reviews_place_id ON place_reviews (place_id);
