# typed: strict
# frozen_string_literal: true

class Partition < ApplicationRecord # rubocop:disable Style/Documentation
  include AASM

  belongs_to :deployment, foreign_key: 'deployment_id'

  scope :prerequisites, -> { where(prerequisite: true) }

  aasm :run_state, column: :run_state, no_direct_assignment: true do
    state :not_run, initial: true
    state :run_failed
    state :run_succeeded
    state :run_state_unknown
    state :run_started
    state :run_enqueued

    event :not_run do
      transitions to: :not_run, guard: proc { false }
    end

    event :run_failed do
      transitions from: [:not_run, :run_enqueued, :run_started], to: :run_failed # rubocop:disable Style/SymbolArray
    end

    event :run_succeeded do
      transitions from: [:run_enqueued, :run_started], to: :run_succeeded # rubocop:disable Style/SymbolArray
    end

    event :run_state_unknown do
      transitions to: :run_state_unknown, guard: proc { false }
    end

    event :run_started do
      transitions from: [:not_run, :run_enqueued], to: :run_started # rubocop:disable Style/SymbolArray
    end

    event :run_enqueued do
      transitions from: [:not_run], to: :run_enqueued
    end
  end

  enum run_state: { not_run: 0, run_failed: 1, run_succeeded: 2, run_state_unknown: 3, run_started: 4, run_enqueued: 5 }

  run_states.each do |name, value|
    const_set name.upcase, value
  end

  TERMINAL_PARTITION_RUN_STATE = T.let([:run_succeeded, :run_failed], T::Array[Symbol]) # rubocop:disable Style/SymbolArray

  def in_completed_run_state?
    TERMINAL_PARTITION_RUN_STATE.any? { |st| run_state.to_s == st.to_s }
  end
end
