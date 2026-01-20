# frozen_string_literal: true

# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

puts "Seeding database..."

# Create default theme if it doesn't exist
if Theme.count.zero?
  puts "Creating default 'Ocean Blue' theme..."
  Theme.create_default_theme
  puts "  Created default theme"
end

# Create sample themes for development
if Rails.env.development? && Theme.count == 1
  puts "Creating sample themes for development..."

  themes = [
    {
      name: 'Forest Green',
      colors: {
        'primary' => '#059669',
        'secondary' => '#64748B',
        'accent' => '#34D399',
        'background_light' => '#FFFFFF',
        'background_dark' => '#0F172A',
        'surface_light' => '#F8FAFC',
        'surface_dark' => '#1E293B',
        'text_light' => '#1E293B',
        'text_dark' => '#F8FAFC'
      }
    },
    {
      name: 'Sunset Orange',
      colors: {
        'primary' => '#EA580C',
        'secondary' => '#64748B',
        'accent' => '#FB923C',
        'background_light' => '#FFFFFF',
        'background_dark' => '#0F172A',
        'surface_light' => '#FFF7ED',
        'surface_dark' => '#1E293B',
        'text_light' => '#1E293B',
        'text_dark' => '#F8FAFC'
      }
    },
    {
      name: 'Royal Purple',
      colors: {
        'primary' => '#7C3AED',
        'secondary' => '#64748B',
        'accent' => '#A78BFA',
        'background_light' => '#FFFFFF',
        'background_dark' => '#0F172A',
        'surface_light' => '#FAF5FF',
        'surface_dark' => '#1E293B',
        'text_light' => '#1E293B',
        'text_dark' => '#F8FAFC'
      }
    }
  ]

  themes.each do |theme_data|
    Theme.find_or_create_by!(name: theme_data[:name]) do |theme|
      theme.colors = theme_data[:colors]
    end
    puts "  Created '#{theme_data[:name]}' theme"
  end
end

# Optionally create a development admin user
if Rails.env.development? && User.count.zero?
  puts "Creating development admin user..."

  user = User.create!(
    email: 'admin@familyhub.local',
    password: 'password123',
    password_confirmation: 'password123',
    first_name: 'Admin',
    last_name: 'User',
    date_of_birth: Date.new(1990, 1, 1),
    city: 'Development City',
    password_changed: true
  )

  puts "  Created admin user: #{user.email} (password: password123)"
end

puts "Seeding complete!"
