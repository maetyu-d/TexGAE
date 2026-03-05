#pragma once

#include <atomic>

namespace gae
{
class IdAllocator
{
public:
    explicit IdAllocator(int start) : next(start) {}

    int allocate() noexcept { return next.fetch_add(1, std::memory_order_relaxed); }

private:
    std::atomic<int> next;
};
} // namespace gae
