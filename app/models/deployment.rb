# typed: false
# frozen_string_literal: true

class Deployment < ApplicationRecord # rubocop:disable Style/Documentation
  include AASM

  belongs_to :application, foreign_key: 'application_id'
  has_many :partitions

  before_destroy :delete_partitions

  aasm column: :state, no_direct_assignment: true do # rubocop:disable Metrics/BlockLength
    state :requested, initial: true
    state :checklists
    state :prerequisites
    state :active
    state :completed_success
    state :completed_failed
    state :rejected
    state :canceled

    event :requested do
      transitions to: :requested, guard: proc { false }
    end

    event :run_checklists do
      transitios from: [:requested], to: :checklists do
        after do
          start_checklists
        end
      end
    end

    event :run do
      transitions from: [:checklists], to: :prerequisites, after: :start_prerequisites, guard: :checklists_succeeded?
      transitions from: [:checklists], to: :rejected, guard: :checklists_failed?
      transitions from: [:requested], to: :active, after: :start_partitions, guard: -> { !prerequisites? }
      transitions from: [:prerequisites], to: :active, after: :start_partitions, guard: :prerequisites_succeeded?
    end

    event :completed_success do
      transitions from: [:active], to: :completed do
        guard do

        end
      end
    end

    event :completed_errored do
      transitions from: [:active], to: :completed
    end

    event :canceled do
      transitions from: [:requested, :prerequisites, :active], to: :canceled # rubocop:disable Style/SymbolArray
    end
  end

  def self.states
    aasm.states.map(&:name)
  end

  # A deployment is a state machine of 5 states:
  #  requested - Just requested and has not been processed.
  #  completed - Attempted (successful or not) and done with.
  #  active    - Attempted (successful or not) but still active for testing.
  #              Applications with auto-deploy enabled will auto-deploy
  #              further pushes to an active deployment's branch.
  #  rejected  - This deployment was rejected and not run.
  #  canceled  - This deployment was canceled while running
  #
  # Sorbet: Enable the state enum to be referenced by named constants
  REQUESTED = 0
  PREREQUISITES = 1
  ACTIVE = 2
  COMPLETED_SUCCESS = 3
  COMPLETED_FAILED = 4
  REJECTED = 5
  CANCELED = 6

  # # Please, update https://github.com/github/hydro-schemas/blob/03c97afb2fccbe25dae91ec06226b55ca9c0677c/proto/hydro/schemas/heaven/v0/deploy_state_event.proto
  # # if you're changing the state enum.
  # # 👇
  enum state: {
    requested: REQUESTED,
    prerequisites: PREREQUISITES,
    active: ACTIVE,
    completed_success: COMPLETED_SUCCESS,
    completed_failed: COMPLETED_SUCCESS,
    rejected: REJECTED,
    canceled: CANCELED
  }

  TERMINAL_DEPLOY_STATES = [:completed, :rejected, :canceled].freeze # rubocop:disable Style/SymbolArray

  # sig { returns(T::Boolean) }
  def in_completed_state?
    TERMINAL_DEPLOY_STATES.any? { |st| state.to_s == st.to_s }
  end

  def create_partitions
    add_prereq_partition if prerequisites?
    add_partition
  end

  def prerequisites?
    application.config['deployment']['prerequisites']
  end

  def add_prereq_partition
    partitions.create!(prerequisite: true)
  end

  def prerequisites_successful?
    partitions.prerequisites.all?(&:run_succeeded?)
  end

  def prerequisites_failed?
    partitions.prerequisites.any?(&:run_failed?)
  end

  def add_partition
    partitions.create!(prerequisite: false)
  end

  def delete_partitions
    partitions.destroy_all
  end

  def start_prerequisites
    partitions.prerequisites.not_run.each(&:run_started!)
  end

  def start_partitions
    partitions.not_run.each(&:run_started!)
  end
end
