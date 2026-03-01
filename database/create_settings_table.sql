-- ============================================
-- MathTuro LMS - System Settings Table
-- Version: 7.0
-- Purpose: Create settings table for system configuration
-- ============================================

-- Create settings table
CREATE TABLE IF NOT EXISTS public.settings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    system_name VARCHAR(100) NOT NULL DEFAULT 'MathTuro',
    language VARCHAR(10) NOT NULL DEFAULT 'en',
    min_password_length INTEGER NOT NULL DEFAULT 8,
    require_special_chars BOOLEAN NOT NULL DEFAULT true,
    smtp_host VARCHAR(255) DEFAULT 'smtp.gmail.com',
    smtp_port INTEGER DEFAULT 587,
    smtp_username VARCHAR(255),
    smtp_password TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Create RLS policies for settings table
ALTER TABLE public.settings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "admin_view_settings" ON public.settings
    FOR SELECT USING (
        EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')
    );

CREATE POLICY "admin_update_settings" ON public.settings
    FOR UPDATE USING (
        EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')
    );

CREATE POLICY "admin_insert_settings" ON public.settings
    FOR INSERT WITH CHECK (
        EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')
    );

-- Create trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_settings_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_settings_updated_at
    BEFORE UPDATE ON public.settings
    FOR EACH ROW EXECUTE FUNCTION update_settings_updated_at();

-- Insert default settings if table is empty
INSERT INTO public.settings (
    system_name,
    language,
    min_password_length,
    require_special_chars,
    smtp_host,
    smtp_port
) VALUES (
    'MathTuro',
    'en',
    8,
    true,
    'smtp.gmail.com',
    587
) ON CONFLICT DO NOTHING;

-- Verify the settings table creation
SELECT 'Settings table created successfully' AS message;
SELECT * FROM public.settings;
