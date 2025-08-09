
**Solution-1:** **Using blocking Poll with timeout**

```
class Solution {

    private final LinkedBlockingQueue<String> nextUp = new LinkedBlockingQueue<>();

    private final Set<String> seen = ConcurrentHashMap.newKeySet();

    private final List<String> ans = Collections.synchronizedList(new ArrayList<>());

    private final AtomicInteger workers = new AtomicInteger(0);

    private final ExecutorService exec = Executors.newVirtualThreadPerTaskExecutor();

  

    private String hostFrom(String url) {

        int protocolEnd = url.indexOf("://");

        String noProtocol = (protocolEnd != -1) ? url.substring(protocolEnd + 3) : url;

        int slashIndex = noProtocol.indexOf('/');

        return (slashIndex != -1) ? noProtocol.substring(0, slashIndex) : noProtocol;

    }

  

    private void task(String url, String host, HtmlParser htmlParser) {

        try {

            for (String next : htmlParser.getUrls(url)) {

                if (hostFrom(next).equals(host) && seen.add(next)) {

                    nextUp.offer(next);

                }

            }

        } finally {

            workers.decrementAndGet();

        }

    }

  

    public List<String> crawl(String startUrl, HtmlParser htmlParser) {

        String startHost = hostFrom(startUrl);

        seen.add(startUrl);

        nextUp.offer(startUrl);

  

        while (true) {

            try {

                String url = nextUp.poll(100, TimeUnit.MILLISECONDS);

                if (url != null) {

                    ans.add(url);

                    workers.incrementAndGet();

                    exec.submit(() -> task(url, startHost, htmlParser));

                } else if (workers.get() == 0) {

                    break;

                }

            } catch (Exception e) {

                Thread.currentThread().interrupt();

                break;

            }

        }

  

        exec.shutdown();

        return ans;

    }

}
```

**Solution-2: Using Semaphore**

```
import java.util.*;

import java.util.concurrent.*;

import java.util.concurrent.atomic.AtomicInteger;

  

class Solution {

    private final LinkedBlockingQueue<String> nextUp = new LinkedBlockingQueue<>();

    private final Set<String> seen = ConcurrentHashMap.newKeySet();

    private final List<String> ans = Collections.synchronizedList(new ArrayList<>());

    private final AtomicInteger workers = new AtomicInteger(0);

    // Semaphore used as a wake-up signal. Releases are accumulated, so no lost wakeups.

    private final Semaphore signal = new Semaphore(0);

    private final ExecutorService exec = Executors.newVirtualThreadPerTaskExecutor();

  

    private String hostFrom(String url) {

        int protocolEnd = url.indexOf("://");

        String noProtocol = (protocolEnd != -1) ? url.substring(protocolEnd + 3) : url;

        int slashIndex = noProtocol.indexOf('/');

        return (slashIndex != -1) ? noProtocol.substring(0, slashIndex) : noProtocol;

    }

  

    private void task(String url, String host, HtmlParser htmlParser) {

        try {

            for (String next : htmlParser.getUrls(url)) {

                if (hostFrom(next).equals(host) && seen.add(next)) {

                    nextUp.offer(next);

                    // Notify main thread that new work is available

                    signal.release();

                }

            }

        } finally {

            // Mark this worker finished and notify in case main thread is waiting for completion.

            if (workers.decrementAndGet() == 0) {

                signal.release();

            }

        }

    }

  

    public List<String> crawl(String startUrl, HtmlParser htmlParser) {

        String startHost = hostFrom(startUrl);

        seen.add(startUrl);

        nextUp.offer(startUrl);

  

        while (true) {

            String url = nextUp.poll();

            if (url != null) {

                ans.add(url);

                workers.incrementAndGet();

                exec.submit(() -> task(url, startHost, htmlParser));

            } else {

                // No immediate URL — if no workers active we're done

                if (workers.get() == 0) break;

  

                // Otherwise wait for a signal (new URL added or worker finished).

                try {

                    signal.acquire();

                } catch (InterruptedException e) {

                    Thread.currentThread().interrupt();

                    break;

                }

            }

        }

  

        // Cleanly shutdown executor and wait for tasks to finish (defensive).

        exec.shutdown();

        try {

            // Small timeout to avoid indefinite hang; adjust as needed.

            if (!exec.awaitTermination(30, TimeUnit.SECONDS)) {

                exec.shutdownNow();

            }

        } catch (InterruptedException e) {

            exec.shutdownNow();

            Thread.currentThread().interrupt();

        }

  

        return ans;

    }

}
```

**Solution-3: Using wait and notify**

```
import java.util.*;

import java.util.concurrent.*;

import java.util.concurrent.atomic.AtomicInteger;

  

class Solution {

    private static final int MAX_THREADS = 100; // Reasonable limit for concurrent requests

    private static final long SHUTDOWN_TIMEOUT_SECONDS = 30;

    // Thread-safe collections for managing crawl state

    private final ConcurrentLinkedQueue<String> urlQueue = new ConcurrentLinkedQueue<>();

    private final Set<String> visited = ConcurrentHashMap.newKeySet();

    private final List<String> results = Collections.synchronizedList(new ArrayList<>());

    // Worker management

    private final AtomicInteger activeWorkers = new AtomicInteger(0);

    private final ExecutorService executor = Executors.newFixedThreadPool(MAX_THREADS);

    // Synchronization primitive - signals when work state changes

    private final Object workLock = new Object();

    /**

     * Extracts hostname from URL, handling various URL formats safely

     */

    private String extractHost(String url) {

        if (url == null || url.isEmpty()) return "";

        try {

            // Remove protocol if present

            String cleanUrl = url;

            int protocolIndex = url.indexOf("://");

            if (protocolIndex != -1) {

                cleanUrl = url.substring(protocolIndex + 3);

            }

            // Extract hostname (everything before first slash or port)

            int slashIndex = cleanUrl.indexOf('/');

            int portIndex = cleanUrl.indexOf(':');

            int endIndex = cleanUrl.length();

            if (slashIndex != -1) endIndex = Math.min(endIndex, slashIndex);

            if (portIndex != -1) endIndex = Math.min(endIndex, portIndex);

            return cleanUrl.substring(0, endIndex).toLowerCase();

        } catch (Exception e) {

            return ""; // Invalid URL format

        }

    }

    /**

     * Worker task that processes a single URL

     */

    private void processUrl(String url, String targetHost, HtmlParser htmlParser) {

        try {

            // Parse the current URL and extract linked URLs

            List<String> linkedUrls = htmlParser.getUrls(url);

            // Filter and queue new URLs from the same host

            for (String linkedUrl : linkedUrls) {

                if (linkedUrl != null &&

                    targetHost.equals(extractHost(linkedUrl)) &&

                    visited.add(linkedUrl)) { // Atomic check-and-set

                    urlQueue.offer(linkedUrl);

                    // Wake up main thread when new work is available

                    synchronized (workLock) {

                        workLock.notify();

                    }

                }

            }

        } catch (Exception e) {

            // Log error in production, continue processing

            System.err.println("Error processing URL " + url + ": " + e.getMessage());

        } finally {

            // Decrement worker count and notify main thread

            int remaining = activeWorkers.decrementAndGet();

            if (remaining == 0) {

                synchronized (workLock) {

                    workLock.notify(); // Wake up main thread when all workers finish

                }

            }

        }

    }

    /**

     * Main crawling method with proper concurrency control

     */

    public List<String> crawl(String startUrl, HtmlParser htmlParser) {

        if (startUrl == null || htmlParser == null) {

            return new ArrayList<>();

        }

        String targetHost = extractHost(startUrl);

        if (targetHost.isEmpty()) {

            return new ArrayList<>();

        }

        // Initialize with starting URL

        visited.add(startUrl);

        urlQueue.offer(startUrl);

        try {

            // Main crawling loop

            while (true) {

                String currentUrl = urlQueue.poll();

                if (currentUrl != null) {

                    // Process this URL

                    results.add(currentUrl);

                    // Submit worker task

                    activeWorkers.incrementAndGet();

                    executor.submit(() -> processUrl(currentUrl, targetHost, htmlParser));

                } else {

                    // No URLs available - check if we should wait or finish

                    synchronized (workLock) {

                        // Double-check pattern: recheck conditions while holding lock

                        if (urlQueue.isEmpty() && activeWorkers.get() == 0) {

                            // No work available and no workers running - we're done

                            break;

                        } else if (urlQueue.isEmpty()) {

                            // No work now, but workers might generate more - wait

                            try {

                                workLock.wait(1000); // Wait with timeout to prevent infinite blocking

                            } catch (InterruptedException e) {

                                Thread.currentThread().interrupt();

                                break;

                            }

                        }

                        // If queue has items after wait, continue main loop

                    }

                }

            }

        } finally {

            // Clean shutdown of executor

            shutdownExecutor();

        }

        return new ArrayList<>(results);

    }

    /**

     * Properly shutdown the executor service

     */

    private void shutdownExecutor() {

        executor.shutdown();

        try {

            if (!executor.awaitTermination(SHUTDOWN_TIMEOUT_SECONDS, TimeUnit.SECONDS)) {

                executor.shutdownNow();

                // Wait a bit more for tasks to respond to being cancelled

                if (!executor.awaitTermination(5, TimeUnit.SECONDS)) {

                    System.err.println("Executor did not terminate gracefully");

                }

            }

        } catch (InterruptedException e) {

            executor.shutdownNow();

            Thread.currentThread().interrupt();

        }

    }

}

```