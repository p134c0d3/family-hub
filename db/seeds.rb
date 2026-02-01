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

  base_colors = Theme.default_colors

  themes = [
    {
      name: 'Forest Green',
      colors: base_colors.merge(
        'primary' => '#059669',
        'secondary' => '#10b981',
        'accent' => '#fbbf24',
        'primary_dark' => '#34d399',
        'secondary_dark' => '#6ee7b7'
      )
    },
    {
      name: 'Sunset Orange',
      colors: base_colors.merge(
        'primary' => '#f97316',
        'secondary' => '#fb923c',
        'accent' => '#fbbf24',
        'primary_dark' => '#fdba74',
        'secondary_dark' => '#fed7aa'
      )
    },
    {
      name: 'Royal Purple',
      colors: base_colors.merge(
        'primary' => '#7c3aed',
        'secondary' => '#8b5cf6',
        'accent' => '#a78bfa',
        'primary_dark' => '#a78bfa',
        'secondary_dark' => '#c4b5fd'
      )
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

# Additional themes are created above in development mode

puts "Seeding complete!"
