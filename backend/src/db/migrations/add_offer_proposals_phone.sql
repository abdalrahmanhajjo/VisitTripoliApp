-- Add phone number to offer proposals for restaurant contact
ALTER TABLE offer_proposals ADD COLUMN IF NOT EXISTS phone VARCHAR(30);
