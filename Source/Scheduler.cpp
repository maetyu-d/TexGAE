#include "Scheduler.h"

#include <juce_core/juce_core.h>

namespace gae
{
void Scheduler::setLookaheadMs(double ms) noexcept
{
    lookaheadMs = ms;
}

double Scheduler::getLookaheadMs() const noexcept
{
    return lookaheadMs;
}

void Scheduler::scheduleIn(double delayMs, Task task)
{
    const auto nowMs = juce::Time::getMillisecondCounterHiRes();
    queue.push({ nowMs + delayMs, std::move(task) });
}

void Scheduler::pump(double nowMs)
{
    while (! queue.empty())
    {
        const auto due = queue.top().dueMs;
        if (due > nowMs)
            break;

        auto task = queue.top().task;
        queue.pop();

        if (task)
            task();
    }
}
} // namespace gae
