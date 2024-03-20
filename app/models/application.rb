# typed: strict
# frozen_string_literal: true

class Application < ApplicationRecord # rubocop:disable Style/Documentation
  include AASM

  has_many :deployments

  before_destroy :delete_deployments

  aasm column: :status, no_direct_assignment: true do # rubocop:disable Metrics/BlockLength,Lint/RedundantCopDisableDirective
    state :active, initial: true
    state :inactive, after: :notify_inactive
    state :invalid_config_error
    state :archived
    state :config_not_found
    state :merge_queue_disabled
    state :repo_not_accessible
    state :repo_not_found

    after_all_transitions :log_status_change

    # allow transition to inactive from any state
    event :inactivate do
      transitions to: :inactive, guard: proc { true }
    end

    event :update_status do
      transitions to: :active, guard: proc { repo_status == ACTIVE && config.present? }
      transitions to: :archived, guard: proc { repo_status == ARCHIVED }
      transitions to: :merge_queue_disabled, guard: proc { repo_status == MERGE_QUEUE_DISABLED }
      transitions to: :repo_not_accessible, guard: proc { repo_status == REPO_NOT_ACCESSIBLE }
      transitions to: :repo_not_found, guard: proc { repo_status == REPO_NOT_FOUND }
      transitions to: :config_not_found, guard: proc { config.nil? && config_error.is_a?(ConfigNotFound) }
      transitions to: :invalid_config_error, guard: proc { config.nil? && config_error.is_a?(InvalidConfigError) }
      transitions to: :inactive, guard: proc { config.nil? && config_error.is_a?(AppNotAllowed) }
    end

    event :activate do
      transitions to: :active, guard: proc { true }
    end
  end

  def log_status_change
    return unless persisted?
    return if status == aasm.to_state

    puts "changing from #{status} to #{aasm.to_state} (event: #{aasm.current_event})"
  end

  def notify_inactive
    puts "notifying that #{name} is inactive..."
  end

  ACTIVE = 0
  INACTIVE = 1
  INVALID_CONFIG_ERROR = 2
  ARCHIVED = 3
  CONFIG_NOT_FOUND = 4
  MERGE_QUEUE_DISABLED = 5
  REPO_NOT_ACCESSIBLE = 6
  REPO_NOT_FOUND = 7

  enum status: {
    active: 0,
    inactive: 1,
    invalid_config_error: 2,
    archived: 3,
    config_not_found: 4,
    merge_queue_disabled: 5,
    repo_not_accessible: 6,
    repo_not_found: 7
  }

  class AppNotAllowed < StandardError # rubocop:disable Style/Documentation
    def initialize(msg = 'Application not allowed')
      super
    end
  end

  class InvalidConfigError < StandardError # rubocop:disable Style/Documentation
    def initialize(msg = 'Application not allowed')
      super
    end
  end

  class ConfigNotFound < StandardError # rubocop:disable Style/Documentation
    def initialize(msg = 'Application not allowed')
      super
    end
  end

  def config
    puts 'STAGE: retrieving config...'
    @config ||= populate_config
  rescue StandardError => e
    puts 'STAGE: error retrieving config...'
    @config_error = e
    nil
  end

  def config_error
    @config_error ||= nil
  end

  def populate_config
    puts 'STAGE: populating config...'
    # current_second = Time.now.sec

    # case current_second % 10
    # when 0
    #   puts 'STAGE: app not allowed...'
    #   raise AppNotAllowed
    # when 1
    #   puts 'STAGE: invalid config error...'
    #   raise InvalidConfigError
    # when 2
    #   puts 'STAGE: config not found...'
    #   raise ConfigNotFound
    # end

    puts 'STAGE: returning config...'
    # { 'deployment' => { 'strategy' => 'kubernetes', 'prerequisites' => current_second.odd? } }
    { 'deployment' => { 'strategy' => 'kubernetes', 'prerequisites' => true } }
  end

  def repo_status
    @repo_status ||= populate_repo_status
  end

  def populate_repo_status
    puts 'STAGE: populating repo status...'
    # current_second = Time.now.sec

    # case current_second % 10
    # when 3
    #   puts 'STAGE: repo archived...'
    #   return ARCHIVED
    # when 4
    #   puts 'STAGE: repo merge queue disabled...'
    #   return MERGE_QUEUE_DISABLED
    # when 5
    #   puts 'STAGE: repo not accessible...'
    #   return REPO_NOT_ACCESSIBLE
    # when 6
    #   puts 'STAGE: repo not found...'
    #   return REPO_NOT_FOUND
    # end

    puts 'STAGE: repo active...'
    ACTIVE
  end

  def create_deployment
    puts 'STAGE: creating deployment...'
    deployments.create!(strategy: config['deployment']['strategy'])
  end

  def delete_deployments
    puts 'STAGE: deleting deployments...'
    deployments.destroy_all
  end
end
