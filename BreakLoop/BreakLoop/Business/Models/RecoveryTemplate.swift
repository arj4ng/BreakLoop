// BreakLoop/ BreakLoop/ Shared/ Models/ RecoveryTemplate.swift

// recovery template
//
// Created by Arjang Khademi on 24.05.2026
/*
  ╔════════════════════════════════════════════════════════╗
  ║  █████╗ ██████╗      ██╗ ██╗  ██╗ ███╗   ██╗  ██████╗  ║
  ║ ██╔══██╗██╔══██╗     ██║ ██║  ██║ ████╗  ██║ ██╔════╝  ║
  ║ ███████║██████╔╝     ██║ ███████║ ██╔██╗ ██║ ██║  ███╗ ║
  ║ ██╔══██║██╔══██╗██   ██║ ╚════██║ ██║╚██╗██║ ██║   ██║ ║
  ║ ██║  ██║██║  ██║╚█████╔╝      ██║ ██║ ╚████║ ╚██████╔╝ ║
  ║ ╚═╝  ╚═╝╚═╝  ╚═╝ ╚════╝       ╚═╝ ╚═╝  ╚═══╝  ╚═════╝  ║
  ╚═════════════════════════════════════════ [ DEV TAG ] ══╝
*/

import Foundation


// MARK: ┏━ [08 GOALS] Recovery Template
// MARK: ┗━ category basierte timeline für spätere quit ui

struct RecoveryStage: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let days: Int
    let durationLabel: String
    let title: String
    let description: String

    init(days: Int, durationLabel: String, title: String, description: String) {
        self.id = "\(days)-\(title.lowercased())"
        self.days = days
        self.durationLabel = durationLabel
        self.title = title
        self.description = description
    }
}

struct RecoveryTemplate: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let category: ConsumableCategory
    let title: String
    let stages: [RecoveryStage]
}

enum RecoveryTemplateRegistry {
    static func template(for category: ConsumableCategory) -> RecoveryTemplate {
        switch category {
        case .nicotine: return nicotine
        case .alcohol: return alcohol
        case .cannabis: return cannabis
        case .caffeine: return caffeine
        case .medicine: return medicine
        case .custom: return custom
        }
    }

    static func template(id: String?, fallback category: ConsumableCategory) -> RecoveryTemplate {
        guard let id else { return template(for: category) }
        return all.first(where: { $0.id == id }) ?? template(for: category)
    }

    static func defaultTemplateID(for category: ConsumableCategory) -> String {
        template(for: category).id
    }

    static var all: [RecoveryTemplate] {
        [nicotine, alcohol, cannabis, caffeine, medicine, custom]
    }

    private static let nicotine = RecoveryTemplate(
        id: "nicotine-core",
        category: .nicotine,
        title: "Nicotine Recovery",
        stages: [
            .init(days: 0, durationLabel: "0-4 HOURS", title: "Cue Break", description: "Habit loop interrupted. First urge spikes can begin."),
            .init(days: 0, durationLabel: "4-8 HOURS", title: "Early Craving Rise", description: "Nicotine drop starts. Restlessness can increase."),
            .init(days: 0, durationLabel: "8-12 HOURS", title: "Withdrawal Onset", description: "Irritability, tension, and concentration dips can appear."),
            .init(days: 0, durationLabel: "12-24 HOURS", title: "Symptom Build", description: "Cravings become more frequent around routine triggers."),
            .init(days: 1, durationLabel: "24-36 HOURS", title: "Nervous System Shift", description: "Body adapts to lower nicotine baseline."),
            .init(days: 1, durationLabel: "36-48 HOURS", title: "Peak Window Start", description: "Cravings and mood friction can feel stronger."),
            .init(days: 2, durationLabel: "DAY 2", title: "High-Intensity Phase", description: "Strong urges common. Keep environment low-friction."),
            .init(days: 3, durationLabel: "DAY 3", title: "Peak Withdrawal", description: "For many users, this is hardest discomfort day."),
            .init(days: 4, durationLabel: "DAY 4", title: "Urge Volatility", description: "Cravings still sharp, but more predictable."),
            .init(days: 5, durationLabel: "DAY 5", title: "First Control Return", description: "More urge waves pass without acting on them."),
            .init(days: 6, durationLabel: "DAY 6-7", title: "Week-1 Completion", description: "Acute pressure begins easing for many users."),
            .init(days: 8, durationLabel: "DAY 8-10", title: "Breathing Shift", description: "Breathing comfort can improve as inflammation settles."),
            .init(days: 11, durationLabel: "DAY 11-14", title: "Week-2 Rebalance", description: "Mood and focus fluctuations often reduce."),
            .init(days: 15, durationLabel: "DAY 15-18", title: "Habit Rewrite", description: "Old cue-response pathways weaken with repetition."),
            .init(days: 19, durationLabel: "DAY 19-21", title: "Craving Spacing", description: "Cravings come less often, usually shorter duration."),
            .init(days: 22, durationLabel: "DAY 22-30", title: "Month-1 Stability", description: "Daily nicotine-free routine feels more natural."),
            .init(days: 31, durationLabel: "DAY 31-60", title: "Month-2 Consolidation", description: "Stress triggers still matter; recovery capacity stronger."),
            .init(days: 61, durationLabel: "DAY 61-90", title: "Month-3 Momentum", description: "Smoke-free identity and confidence strengthen."),
            .init(days: 120, durationLabel: "MONTH 4-6", title: "Trigger Maturity", description: "High-risk contexts become easier to handle."),
            .init(days: 180, durationLabel: "MONTH 6-12", title: "Long-Term Maintenance", description: "Sustained control with lower day-to-day effort.")
        ]
    )

    private static let alcohol = RecoveryTemplate(
        id: "alcohol-core",
        category: .alcohol,
        title: "Alcohol Recovery",
        stages: [
            .init(days: 0, durationLabel: "0-6 HOURS", title: "Early Separation", description: "First no-alcohol block starts. Cravings can appear quickly."),
            .init(days: 0, durationLabel: "6-12 HOURS", title: "Mild Withdrawal Start", description: "Anxiety, tremor, headache, nausea, sweating may begin."),
            .init(days: 0, durationLabel: "12-24 HOURS", title: "Symptom Rise", description: "Withdrawal intensity can increase. Sleep disturbance common."),
            .init(days: 1, durationLabel: "24-36 HOURS", title: "Peak Risk Build", description: "Acute symptoms can intensify. Medical monitoring may be needed."),
            .init(days: 1, durationLabel: "36-48 HOURS", title: "Seizure-Risk Window", description: "Seizure risk remains elevated in this phase for some users."),
            .init(days: 2, durationLabel: "DAY 2", title: "High-Alert Phase", description: "Strong symptoms may continue. Keep environment low-stress."),
            .init(days: 3, durationLabel: "DAY 3", title: "DT Risk Window", description: "Delirium tremens risk can emerge around this period in severe cases."),
            .init(days: 4, durationLabel: "DAY 4", title: "Acute Stabilizing Start", description: "For many users, severe symptoms begin easing from here."),
            .init(days: 5, durationLabel: "DAY 5", title: "Physical Relief Trend", description: "Shakes, nausea, sweating often reduce, but fatigue can remain."),
            .init(days: 6, durationLabel: "DAY 6-7", title: "First Week Passage", description: "Acute withdrawal often resolves within this timeframe."),
            .init(days: 8, durationLabel: "DAY 8-10", title: "Sleep Rebuild Start", description: "Sleep may still feel uneven while brain chemistry rebalances."),
            .init(days: 11, durationLabel: "DAY 11-14", title: "Week-2 Rebalance", description: "Mood and energy usually become more predictable."),
            .init(days: 15, durationLabel: "DAY 15-18", title: "Clarity Return", description: "Attention and decision quality often improve."),
            .init(days: 19, durationLabel: "DAY 19-21", title: "Craving Spacing", description: "Cravings usually come less often, with shorter duration."),
            .init(days: 22, durationLabel: "DAY 22-30", title: "Month-1 Grounding", description: "Routine without alcohol feels more achievable day-to-day."),
            .init(days: 31, durationLabel: "DAY 31-60", title: "Month-2 Consolidation", description: "Habits strengthen. Stress triggers still need active strategy."),
            .init(days: 61, durationLabel: "DAY 61-90", title: "Month-3 Stability", description: "Emotional regulation and routine confidence often improve."),
            .init(days: 120, durationLabel: "MONTH 4-6", title: "Protracted Recovery", description: "Residual sleep or mood symptoms may still fade gradually."),
            .init(days: 180, durationLabel: "MONTH 6-12", title: "Long-Term Maintenance", description: "Lower relapse risk with strong support and consistent routines.")
        ]
    )

    private static let cannabis = RecoveryTemplate(
        id: "cannabis-core",
        category: .cannabis,
        title: "Cannabis Recovery",
        stages: [
            .init(days: 0, durationLabel: "0-6 HOURS", title: "Routine Break Shock", description: "First break from habit loop. Urges can start quickly."),
            .init(days: 0, durationLabel: "6-12 HOURS", title: "Early Urge Waves", description: "Short craving bursts tied to normal use times."),
            .init(days: 0, durationLabel: "12-24 HOURS", title: "Irritability Onset", description: "Mood can feel edgy. Patience may drop."),
            .init(days: 1, durationLabel: "24-36 HOURS", title: "Restlessness Rise", description: "Anxiety and restlessness become more noticeable."),
            .init(days: 1, durationLabel: "36-48 HOURS", title: "Sleep Disruption", description: "Harder to fall asleep. Night waking may increase."),
            .init(days: 3, durationLabel: "DAY 3", title: "Craving Spike", description: "Craving intensity often peaks around this stage."),
            .init(days: 4, durationLabel: "DAY 4", title: "Mood Volatility Peak", description: "Irritability and mood swings can feel strongest."),
            .init(days: 5, durationLabel: "DAY 5", title: "Physical Discomfort Window", description: "Headache, sweating, chills, stomach discomfort can appear."),
            .init(days: 6, durationLabel: "DAY 6-7", title: "Peak Easing Start", description: "Symptoms often begin to ease, but cravings still hit."),
            .init(days: 8, durationLabel: "DAY 8-10", title: "Appetite Returning", description: "Appetite and calm usually begin normalizing."),
            .init(days: 11, durationLabel: "DAY 11-14", title: "Week-2 Stabilizing", description: "Emotional intensity lowers. Better daily control."),
            .init(days: 15, durationLabel: "DAY 15-18", title: "Clarity Rebuild", description: "Focus and mental clarity begin to recover."),
            .init(days: 19, durationLabel: "DAY 19-21", title: "Lower Reactivity", description: "Triggers still present, but response feels steadier."),
            .init(days: 22, durationLabel: "DAY 22-30", title: "Resilience Build", description: "Symptoms become milder and less frequent for many."),
            .init(days: 31, durationLabel: "DAY 31-60", title: "Month-2 Consolidation", description: "Baseline more stable. Cue-driven cravings can remain."),
            .init(days: 61, durationLabel: "DAY 61-90", title: "Month-3 Habit Lock-In", description: "New routines feel more natural and automatic."),
            .init(days: 120, durationLabel: "MONTH 4-6", title: "Trigger Maturity", description: "Better stress handling without returning to old patterns."),
            .init(days: 180, durationLabel: "MONTH 6-12", title: "Identity Maintenance", description: "Long-term stability strengthens with consistent routines.")
        ]
    )

    private static let caffeine = RecoveryTemplate(
        id: "caffeine-core",
        category: .caffeine,
        title: "Caffeine Recovery",
        stages: [
            .init(days: 0, durationLabel: "0-6 HOURS", title: "Cue Break", description: "Routine coffee/energy cues become very noticeable."),
            .init(days: 0, durationLabel: "6-12 HOURS", title: "Early Dip", description: "Mild tiredness and slower alertness can appear."),
            .init(days: 0, durationLabel: "12-18 HOURS", title: "Withdrawal Onset", description: "Typical withdrawal symptoms start in this window."),
            .init(days: 0, durationLabel: "18-24 HOURS", title: "Headache Build", description: "Headache pressure may begin rising clearly."),
            .init(days: 1, durationLabel: "24-36 HOURS", title: "Peak Window Start", description: "Fatigue, irritability, and focus drop can intensify."),
            .init(days: 1, durationLabel: "36-48 HOURS", title: "Symptom Apex", description: "Withdrawal often reaches strongest intensity here."),
            .init(days: 2, durationLabel: "DAY 2", title: "High-Impact Phase", description: "Brain fog and low drive can feel most disruptive."),
            .init(days: 3, durationLabel: "DAY 3", title: "Peak-Tail Transition", description: "Peak discomfort can persist but usually starts easing."),
            .init(days: 4, durationLabel: "DAY 4", title: "Pressure Release", description: "Headache and irritability often begin dropping."),
            .init(days: 5, durationLabel: "DAY 5", title: "Energy Rebound Start", description: "Natural wakefulness starts returning in short blocks."),
            .init(days: 6, durationLabel: "DAY 6-7", title: "Week-1 Passage", description: "Most acute withdrawal often resolves by this stage."),
            .init(days: 8, durationLabel: "DAY 8-9", title: "End of Acute Window", description: "Common 2-9 day withdrawal window usually closes."),
            .init(days: 10, durationLabel: "DAY 10-14", title: "Week-2 Rebalance", description: "Sleep and daytime rhythm become more predictable."),
            .init(days: 15, durationLabel: "DAY 15-18", title: "Cognitive Smoothing", description: "Attention steadies without stimulant spikes."),
            .init(days: 19, durationLabel: "DAY 19-21", title: "Crash Reduction", description: "Afternoon energy crashes tend to reduce."),
            .init(days: 22, durationLabel: "DAY 22-30", title: "Month-1 Rhythm", description: "Energy pattern feels more stable across full week."),
            .init(days: 31, durationLabel: "DAY 31-60", title: "Month-2 Consolidation", description: "Lower-caffeine routine feels less effortful."),
            .init(days: 61, durationLabel: "DAY 61-90", title: "Month-3 Stability", description: "Sleep-energy cycle usually stays more consistent."),
            .init(days: 120, durationLabel: "MONTH 4-6", title: "Trigger Control", description: "Stress-triggered caffeine urges become easier to manage."),
            .init(days: 180, durationLabel: "MONTH 6-12", title: "Long-Term Maintenance", description: "Sustained pattern holds with fewer relapse urges.")
        ]
    )

    private static let medicine = RecoveryTemplate(
        id: "medicine-core",
        category: .medicine,
        title: "Medicine Change Timeline",
        stages: [
            .init(days: 1, durationLabel: "DAY 1", title: "Start Tracking", description: "You started medicine change tracking for this item."),
            .init(days: 3, durationLabel: "DAY 3", title: "Early Check-In", description: "Log patterns, symptoms, and routine friction."),
            .init(days: 7, durationLabel: "DAY 7", title: "Week-1 Review", description: "Review what worked and what needs adjustment."),
            .init(days: 14, durationLabel: "DAY 14", title: "Stabilizing", description: "Consistency matters more than perfect execution."),
            .init(days: 30, durationLabel: "DAY 30", title: "Month-1 Baseline", description: "You now have meaningful trend data."),
            .init(days: 60, durationLabel: "DAY 60", title: "Month-2 Pattern", description: "Routine quality and adherence become clearer."),
            .init(days: 90, durationLabel: "DAY 90", title: "Month-3 Consolidation", description: "Use trends to refine next phase safely."),
            .init(days: 180, durationLabel: "MONTH 6", title: "Long-Term Monitoring", description: "Sustained tracking supports durable decisions.")
        ]
    )

    private static let custom = RecoveryTemplate(
        id: "custom-core",
        category: .custom,
        title: "Recovery Timeline",
        stages: [
            .init(days: 1, durationLabel: "DAY 1", title: "Start", description: "You started a new pattern. Keep first steps small."),
            .init(days: 3, durationLabel: "DAY 3", title: "Early Friction", description: "Old habits may pull back. Keep environment supportive."),
            .init(days: 7, durationLabel: "DAY 7", title: "First Week", description: "Consistency in routine matters more than perfection."),
            .init(days: 14, durationLabel: "DAY 14", title: "Stabilizing", description: "Triggers are still there, response gets stronger."),
            .init(days: 30, durationLabel: "DAY 30", title: "Momentum", description: "Progress starts to feel more repeatable."),
            .init(days: 90, durationLabel: "DAY 90", title: "Sustained Pattern", description: "New behavior becomes part of normal routine.")
        ]
    )
}
