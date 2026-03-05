#pragma once

#include <functional>
#include <queue>
#include <vector>

namespace gae
{
class Scheduler
{
public:
    using Task = std::function<void()>;

    void setLookaheadMs(double ms) noexcept;
    double getLookaheadMs() const noexcept;

    void scheduleIn(double delayMs, Task task);
    void pump(double nowMs);

private:
    struct ScheduledTask
    {
        double dueMs {};
        Task task;

        bool operator<(const ScheduledTask& other) const noexcept
        {
            return dueMs > other.dueMs;
        }
    };

    double lookaheadMs { 25.0 };
    std::priority_queue<ScheduledTask> queue;
};
} // namespace gae
