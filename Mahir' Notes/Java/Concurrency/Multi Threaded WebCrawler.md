
**Solution-1:** **Using blocking Poll with timeout**

```

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


```