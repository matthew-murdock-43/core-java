# NeetCode 150 - Java Solutions

This independent study guide follows the current NeetCode 150 roadmap and provides a concise Java solution, core idea, and complexity analysis for every problem.

**Snapshot:** August 30, 2026. The roadmap contains 150 problems across 18 topics: 28 Easy, 101 Medium, and 21 Hard. LeetCode Premium problems are marked in their headings.

**Notes:** `java.util.*`, `ListNode`, `TreeNode`, and problem-specific `Node` classes are assumed to be supplied by the online judge. Code uses standard LeetCode-style method signatures. Solutions are independently written, concise, and interview-oriented.

**Roadmap reference:** <https://neetcode.io/practice/practice/neetcode150>

## Contents

Problem numbers follow this document's topic order.

| Problems | Topic | Problems | Topic |
|---:|---|---:|---|
| 1-9 | Arrays & Hashing | 10-14 | Two Pointers |
| 15-20 | Sliding Window | 21-26 | Stack |
| 27-33 | Binary Search | 34-44 | Linked List |
| 45-59 | Trees | 60-66 | Heap / Priority Queue |
| 67-76 | Backtracking | 77-79 | Tries |
| 80-92 | Graphs | 93-98 | Advanced Graphs |
| 99-110 | 1-D Dynamic Programming | 111-121 | 2-D Dynamic Programming |
| 122-129 | Greedy | 130-135 | Intervals |
| 136-143 | Math & Geometry | 144-150 | Bit Manipulation |

## Arrays & Hashing

### 1. Contains Duplicate (LC 217, Easy)

**Idea:** Insert values into a hash set; a failed insertion reveals the first duplicate.  
**Time:** O(n) **Space:** O(n)

```java
class Solution {
    public boolean containsDuplicate(int[] nums) {
        Set<Integer> seen = new HashSet<>();
        for (int value : nums) {
            if (!seen.add(value)) return true;
        }
        return false;
    }
}
```

### 2. Valid Anagram (LC 242, Easy)

**Idea:** Increment counts for one string and decrement them for the other.  
**Time:** O(n) **Space:** O(1)

```java
class Solution {
    public boolean isAnagram(String s, String t) {
        if (s.length() != t.length()) return false;
        int[] count = new int[26];
        for (int i = 0; i < s.length(); i++) {
            count[s.charAt(i) - 'a']++;
            count[t.charAt(i) - 'a']--;
        }
        for (int x : count) if (x != 0) return false;
        return true;
    }
}
```

### 3. Two Sum (LC 1, Easy)

**Idea:** Store each value's index and check whether its complement has already appeared.  
**Time:** O(n) **Space:** O(n)

```java
class Solution {
    public int[] twoSum(int[] nums, int target) {
        Map<Integer, Integer> index = new HashMap<>();
        for (int i = 0; i < nums.length; i++) {
            int need = target - nums[i];
            if (index.containsKey(need)) return new int[]{index.get(need), i};
            index.put(nums[i], i);
        }
        return new int[0];
    }
}
```

### 4. Group Anagrams (LC 49, Medium)

**Idea:** Use the sorted characters of each word as its group key.  
**Time:** O(total characters * log word length) **Space:** O(total characters)

```java
class Solution {
    public List<List<String>> groupAnagrams(String[] strs) {
        Map<String, List<String>> groups = new HashMap<>();
        for (String s : strs) {
            char[] chars = s.toCharArray();
            Arrays.sort(chars);
            String key = new String(chars);
            groups.computeIfAbsent(key, k -> new ArrayList<>()).add(s);
        }
        return new ArrayList<>(groups.values());
    }
}
```

### 5. Top K Frequent Elements (LC 347, Medium)

**Idea:** Count each value, place values into frequency buckets, then scan buckets from high to low.  
**Time:** O(n) **Space:** O(n)

```java
class Solution {
    public int[] topKFrequent(int[] nums, int k) {
        Map<Integer, Integer> frequency = new HashMap<>();
        for (int value : nums) {
            frequency.put(value, frequency.getOrDefault(value, 0) + 1);
        }

        List<Integer>[] buckets = new List[nums.length + 1];
        for (Map.Entry<Integer, Integer> entry : frequency.entrySet()) {
            int count = entry.getValue();
            if (buckets[count] == null) buckets[count] = new ArrayList<>();
            buckets[count].add(entry.getKey());
        }

        int[] answer = new int[k];
        int write = 0;
        for (int count = buckets.length - 1; count >= 0 && write < k; count--) {
            if (buckets[count] == null) continue;
            for (int value : buckets[count]) {
                answer[write++] = value;
                if (write == k) break;
            }
        }
        return answer;
    }
}
```

### 6. Encode and Decode Strings (LC 271, Medium, Premium)

**Idea:** Prefix every string with its decimal length and a delimiter, so decoding never depends on the string contents.  
**Time:** O(C) **Space:** O(C)

```java
class Codec {
    public String encode(List<String> strs) {
        StringBuilder encoded = new StringBuilder();
        for (String value : strs) {
            encoded.append(value.length()).append('#').append(value);
        }
        return encoded.toString();
    }

    public List<String> decode(String s) {
        List<String> decoded = new ArrayList<>();
        int i = 0;
        while (i < s.length()) {
            int delimiter = i;
            while (s.charAt(delimiter) != '#') delimiter++;
            int length = Integer.parseInt(s.substring(i, delimiter));
            int start = delimiter + 1;
            decoded.add(s.substring(start, start + length));
            i = start + length;
        }
        return decoded;
    }
}
```

### 7. Product of Array Except Self (LC 238, Medium)

**Idea:** Write prefix products into the answer, then multiply by a rolling suffix product.  
**Time:** O(n) **Space:** O(1) extra, excluding output

```java
class Solution {
    public int[] productExceptSelf(int[] nums) {
        int n = nums.length;
        int[] ans = new int[n];
        ans[0] = 1;
        for (int i = 1; i < n; i++) ans[i] = ans[i - 1] * nums[i - 1];
        int suffix = 1;
        for (int i = n - 1; i >= 0; i--) {
            ans[i] *= suffix;
            suffix *= nums[i];
        }
        return ans;
    }
}
```

### 8. Valid Sudoku (LC 36, Medium)

**Idea:** Record each digit in its row, column, and 3-by-3 box; any repeated key is invalid.  
**Time:** O(1) for a 9-by-9 board **Space:** O(1)

```java
class Solution {
    public boolean isValidSudoku(char[][] board) {
        boolean[][] rows = new boolean[9][9];
        boolean[][] cols = new boolean[9][9];
        boolean[][] boxes = new boolean[9][9];
        for (int r = 0; r < 9; r++) {
            for (int c = 0; c < 9; c++) {
                if (board[r][c] == '.') continue;
                int digit = board[r][c] - '1';
                int box = (r / 3) * 3 + c / 3;
                if (rows[r][digit] || cols[c][digit] || boxes[box][digit]) return false;
                rows[r][digit] = cols[c][digit] = boxes[box][digit] = true;
            }
        }
        return true;
    }
}
```

### 9. Longest Consecutive Sequence (LC 128, Medium)

**Idea:** Start counting only at values whose predecessor is absent.  
**Time:** O(n) average **Space:** O(n)

```java
class Solution {
    public int longestConsecutive(int[] nums) {
        Set<Integer> set = new HashSet<>();
        for (int value : nums) set.add(value);
        int best = 0;
        for (int value : set) {
            if (value != Integer.MIN_VALUE && set.contains(value - 1)) continue;
            int current = value, length = 1;
            while (current != Integer.MAX_VALUE && set.contains(current + 1)) {
                current++;
                length++;
            }
            best = Math.max(best, length);
        }
        return best;
    }
}
```

## Two Pointers

### 10. Valid Palindrome (LC 125, Easy)

**Idea:** Move inward from both ends, skipping non-alphanumeric characters and comparing lowercase values.  
**Time:** O(n) **Space:** O(1)

```java
class Solution {
    public boolean isPalindrome(String s) {
        int l = 0, r = s.length() - 1;
        while (l < r) {
            while (l < r && !Character.isLetterOrDigit(s.charAt(l))) l++;
            while (l < r && !Character.isLetterOrDigit(s.charAt(r))) r--;
            if (Character.toLowerCase(s.charAt(l)) != Character.toLowerCase(s.charAt(r))) {
                return false;
            }
            l++;
            r--;
        }
        return true;
    }
}
```

### 11. Two Sum II - Input Array Is Sorted (LC 167, Medium)

**Idea:** Move the left pointer for a small sum and the right pointer for a large sum.  
**Time:** O(n) **Space:** O(1)

```java
class Solution {
    public int[] twoSum(int[] numbers, int target) {
        int l = 0, r = numbers.length - 1;
        while (l < r) {
            int sum = numbers[l] + numbers[r];
            if (sum == target) return new int[]{l + 1, r + 1};
            if (sum < target) l++;
            else r--;
        }
        return new int[0];
    }
}
```

### 12. 3Sum (LC 15, Medium)

**Idea:** Sort, fix one value, and solve the remaining two-sum problem with inward pointers.  
**Time:** O(n^2) **Space:** O(log n) to O(n), depending on the sort

```java
class Solution {
    public List<List<Integer>> threeSum(int[] nums) {
        Arrays.sort(nums);
        List<List<Integer>> ans = new ArrayList<>();
        for (int i = 0; i < nums.length - 2; i++) {
            if (i > 0 && nums[i] == nums[i - 1]) continue;
            if (nums[i] > 0) break;
            int l = i + 1, r = nums.length - 1;
            while (l < r) {
                int sum = nums[i] + nums[l] + nums[r];
                if (sum < 0) l++;
                else if (sum > 0) r--;
                else {
                    ans.add(Arrays.asList(nums[i], nums[l], nums[r]));
                    int left = nums[l], right = nums[r];
                    while (l < r && nums[l] == left) l++;
                    while (l < r && nums[r] == right) r--;
                }
            }
        }
        return ans;
    }
}
```

### 13. Container With Most Water (LC 11, Medium)

**Idea:** Evaluate both ends, then move the shorter wall because only a taller wall can improve the area.  
**Time:** O(n) **Space:** O(1)

```java
class Solution {
    public int maxArea(int[] height) {
        int l = 0, r = height.length - 1, best = 0;
        while (l < r) {
            best = Math.max(best, Math.min(height[l], height[r]) * (r - l));
            if (height[l] < height[r]) l++;
            else r--;
        }
        return best;
    }
}
```

### 14. Trapping Rain Water (LC 42, Hard)

**Idea:** Move the side with the smaller maximum; that side's trapped water is already determined.  
**Time:** O(n) **Space:** O(1)

```java
class Solution {
    public int trap(int[] height) {
        int l = 0, r = height.length - 1;
        int leftMax = 0, rightMax = 0, water = 0;
        while (l < r) {
            if (height[l] <= height[r]) {
                leftMax = Math.max(leftMax, height[l]);
                water += leftMax - height[l++];
            } else {
                rightMax = Math.max(rightMax, height[r]);
                water += rightMax - height[r--];
            }
        }
        return water;
    }
}
```

## Sliding Window

### 15. Best Time to Buy and Sell Stock (LC 121, Easy)

**Idea:** Track the cheapest price seen and the best profit from selling today.  
**Time:** O(n) **Space:** O(1)

```java
class Solution {
    public int maxProfit(int[] prices) {
        int minPrice = Integer.MAX_VALUE, best = 0;
        for (int price : prices) {
            minPrice = Math.min(minPrice, price);
            best = Math.max(best, price - minPrice);
        }
        return best;
    }
}
```

### 16. Longest Substring Without Repeating Characters (LC 3, Medium)

**Idea:** Store the next valid position after each character and jump the left edge past duplicates.  
**Time:** O(n) **Space:** O(1) for the fixed character table

```java
class Solution {
    public int lengthOfLongestSubstring(String s) {
        int[] next = new int[128];
        int left = 0, best = 0;
        for (int right = 0; right < s.length(); right++) {
            char c = s.charAt(right);
            left = Math.max(left, next[c]);
            best = Math.max(best, right - left + 1);
            next[c] = right + 1;
        }
        return best;
    }
}
```

### 17. Longest Repeating Character Replacement (LC 424, Medium)

**Idea:** Maintain a window whose non-majority characters can be replaced with at most k edits.  
**Time:** O(n) **Space:** O(1)

```java
class Solution {
    public int characterReplacement(String s, int k) {
        int[] count = new int[26];
        int left = 0, maxFrequency = 0, best = 0;
        for (int right = 0; right < s.length(); right++) {
            maxFrequency = Math.max(maxFrequency, ++count[s.charAt(right) - 'A']);
            while (right - left + 1 - maxFrequency > k) {
                count[s.charAt(left++) - 'A']--;
            }
            best = Math.max(best, right - left + 1);
        }
        return best;
    }
}
```

### 18. Permutation in String (LC 567, Medium)

**Idea:** Compare fixed-size character-frequency windows in s2 with the frequency vector of s1.  
**Time:** O(n) **Space:** O(1)

```java
class Solution {
    public boolean checkInclusion(String s1, String s2) {
        if (s1.length() > s2.length()) return false;
        int[] need = new int[26];
        int[] window = new int[26];
        for (char c : s1.toCharArray()) need[c - 'a']++;

        for (int right = 0; right < s2.length(); right++) {
            window[s2.charAt(right) - 'a']++;
            if (right >= s1.length()) {
                window[s2.charAt(right - s1.length()) - 'a']--;
            }
            if (right >= s1.length() - 1 && Arrays.equals(need, window)) return true;
        }
        return false;
    }
}
```

### 19. Minimum Window Substring (LC 76, Hard)

**Idea:** Expand until all required characters are covered, then shrink while preserving coverage.  
**Time:** O(n + m) **Space:** O(1) for the fixed character table

```java
class Solution {
    public String minWindow(String s, String t) {
        if (t.length() > s.length()) return "";
        int[] need = new int[128];
        for (char c : t.toCharArray()) need[c]++;
        int missing = t.length(), left = 0, start = 0, best = Integer.MAX_VALUE;

        for (int right = 0; right < s.length(); right++) {
            char c = s.charAt(right);
            if (need[c]-- > 0) missing--;
            while (missing == 0) {
                if (right - left + 1 < best) {
                    best = right - left + 1;
                    start = left;
                }
                char removed = s.charAt(left++);
                if (++need[removed] > 0) missing++;
            }
        }
        return best == Integer.MAX_VALUE ? "" : s.substring(start, start + best);
    }
}
```

### 20. Sliding Window Maximum (LC 239, Hard)

**Idea:** Keep candidate indices in a decreasing deque; the front is the maximum for the current window.  
**Time:** O(n) **Space:** O(k)

```java
class Solution {
    public int[] maxSlidingWindow(int[] nums, int k) {
        int[] answer = new int[nums.length - k + 1];
        Deque<Integer> deque = new ArrayDeque<>();
        int write = 0;

        for (int right = 0; right < nums.length; right++) {
            while (!deque.isEmpty() && deque.peekFirst() <= right - k) deque.pollFirst();
            while (!deque.isEmpty() && nums[deque.peekLast()] <= nums[right]) deque.pollLast();
            deque.offerLast(right);
            if (right >= k - 1) answer[write++] = nums[deque.peekFirst()];
        }
        return answer;
    }
}
```

## Stack

### 21. Valid Parentheses (LC 20, Easy)

**Idea:** Push expected closing brackets and match each closing bracket against the stack top.  
**Time:** O(n) **Space:** O(n)

```java
class Solution {
    public boolean isValid(String s) {
        Deque<Character> stack = new ArrayDeque<>();
        for (char c : s.toCharArray()) {
            if (c == '(') stack.push(')');
            else if (c == '[') stack.push(']');
            else if (c == '{') stack.push('}');
            else if (stack.isEmpty() || stack.pop() != c) return false;
        }
        return stack.isEmpty();
    }
}
```

### 22. Min Stack (LC 155, Medium)

**Idea:** Store each value together with the minimum at the time it is pushed.  
**Time:** O(1) per operation **Space:** O(n)

```java
class MinStack {
    private final Deque<int[]> stack = new ArrayDeque<>();

    public MinStack() {}

    public void push(int val) {
        int min = stack.isEmpty() ? val : Math.min(val, stack.peek()[1]);
        stack.push(new int[]{val, min});
    }

    public void pop() {
        stack.pop();
    }

    public int top() {
        return stack.peek()[0];
    }

    public int getMin() {
        return stack.peek()[1];
    }
}
```

### 23. Evaluate Reverse Polish Notation (LC 150, Medium)

**Idea:** Push numbers; for an operator, pop the right operand and then the left operand.  
**Time:** O(n) **Space:** O(n)

```java
class Solution {
    public int evalRPN(String[] tokens) {
        Deque<Integer> stack = new ArrayDeque<>();
        for (String token : tokens) {
            if (token.length() > 1 || Character.isDigit(token.charAt(0))) {
                stack.push(Integer.parseInt(token));
                continue;
            }
            int b = stack.pop(), a = stack.pop();
            switch (token.charAt(0)) {
                case '+': stack.push(a + b); break;
                case '-': stack.push(a - b); break;
                case '*': stack.push(a * b); break;
                default: stack.push(a / b);
            }
        }
        return stack.pop();
    }
}
```

### 24. Daily Temperatures (LC 739, Medium)

**Idea:** Keep unresolved day indices in a decreasing stack and resolve them when a warmer day arrives.  
**Time:** O(n) **Space:** O(n)

```java
class Solution {
    public int[] dailyTemperatures(int[] temperatures) {
        int[] answer = new int[temperatures.length];
        Deque<Integer> stack = new ArrayDeque<>();
        for (int day = 0; day < temperatures.length; day++) {
            while (!stack.isEmpty() && temperatures[day] > temperatures[stack.peek()]) {
                int previous = stack.pop();
                answer[previous] = day - previous;
            }
            stack.push(day);
        }
        return answer;
    }
}
```

### 25. Car Fleet (LC 853, Medium)

**Idea:** Process cars from nearest to farthest from the target; a later arrival time starts a new fleet.  
**Time:** O(n log n) **Space:** O(n)

```java
class Solution {
    public int carFleet(int target, int[] position, int[] speed) {
        int[][] cars = new int[position.length][2];
        for (int i = 0; i < position.length; i++) {
            cars[i][0] = position[i];
            cars[i][1] = speed[i];
        }
        Arrays.sort(cars, (a, b) -> Integer.compare(b[0], a[0]));

        int fleets = 0;
        double slowestArrival = -1.0;
        for (int[] car : cars) {
            double arrival = (target - car[0]) / (double) car[1];
            if (arrival > slowestArrival) {
                fleets++;
                slowestArrival = arrival;
            }
        }
        return fleets;
    }
}
```

### 26. Largest Rectangle in Histogram (LC 84, Hard)

**Idea:** Use an increasing stack of bar indices; when a lower bar appears, finalize rectangles for taller bars.  
**Time:** O(n) **Space:** O(n)

```java
class Solution {
    public int largestRectangleArea(int[] heights) {
        Deque<Integer> stack = new ArrayDeque<>();
        int best = 0;
        for (int i = 0; i <= heights.length; i++) {
            int current = i == heights.length ? 0 : heights[i];
            while (!stack.isEmpty() && heights[stack.peek()] > current) {
                int height = heights[stack.pop()];
                int left = stack.isEmpty() ? -1 : stack.peek();
                best = Math.max(best, height * (i - left - 1));
            }
            stack.push(i);
        }
        return best;
    }
}
```

## Binary Search

### 27. Binary Search (LC 704, Easy)

**Idea:** Binary-search the sorted array, discarding half of the remaining range after each comparison.  
**Time:** O(log n) **Space:** O(1)

```java
class Solution {
    public int search(int[] nums, int target) {
        int left = 0, right = nums.length - 1;
        while (left <= right) {
            int mid = left + (right - left) / 2;
            if (nums[mid] == target) return mid;
            if (nums[mid] < target) left = mid + 1;
            else right = mid - 1;
        }
        return -1;
    }
}
```

### 28. Search a 2D Matrix (LC 74, Medium)

**Idea:** Treat the sorted matrix as one flattened sorted array and binary-search it.  
**Time:** O(log(mn)) **Space:** O(1)

```java
class Solution {
    public boolean searchMatrix(int[][] matrix, int target) {
        int rows = matrix.length, cols = matrix[0].length;
        int left = 0, right = rows * cols - 1;
        while (left <= right) {
            int mid = left + (right - left) / 2;
            int value = matrix[mid / cols][mid % cols];
            if (value == target) return true;
            if (value < target) left = mid + 1;
            else right = mid - 1;
        }
        return false;
    }
}
```

### 29. Koko Eating Bananas (LC 875, Medium)

**Idea:** Binary-search the eating speed and test each candidate by summing the required ceiling-divided hours.  
**Time:** O(n log M) **Space:** O(1)

```java
class Solution {
    public int minEatingSpeed(int[] piles, int h) {
        int left = 1, right = 0;
        for (int pile : piles) right = Math.max(right, pile);

        while (left < right) {
            int speed = left + (right - left) / 2;
            long hours = 0;
            for (int pile : piles) hours += (pile + (long) speed - 1) / speed;
            if (hours <= h) right = speed;
            else left = speed + 1;
        }
        return left;
    }
}
```

### 30. Find Minimum in Rotated Sorted Array (LC 153, Medium)

**Idea:** Compare the middle value with the right boundary to locate the rotation minimum.  
**Time:** O(log n) **Space:** O(1)

```java
class Solution {
    public int findMin(int[] nums) {
        int left = 0, right = nums.length - 1;
        while (left < right) {
            int mid = left + (right - left) / 2;
            if (nums[mid] > nums[right]) left = mid + 1;
            else right = mid;
        }
        return nums[left];
    }
}
```

### 31. Search in Rotated Sorted Array (LC 33, Medium)

**Idea:** One half is always sorted; use that fact to discard the impossible half.  
**Time:** O(log n) **Space:** O(1)

```java
class Solution {
    public int search(int[] nums, int target) {
        int left = 0, right = nums.length - 1;
        while (left <= right) {
            int mid = left + (right - left) / 2;
            if (nums[mid] == target) return mid;
            if (nums[left] <= nums[mid]) {
                if (nums[left] <= target && target < nums[mid]) right = mid - 1;
                else left = mid + 1;
            } else {
                if (nums[mid] < target && target <= nums[right]) left = mid + 1;
                else right = mid - 1;
            }
        }
        return -1;
    }
}
```

### 32. Time Based Key-Value Store (LC 981, Medium)

**Idea:** Store each key's values in timestamp order and binary-search the latest timestamp not exceeding the query.  
**Time:** set: O(1), get: O(log n) **Space:** O(n)

```java
class TimeMap {
    private static class Entry {
        int timestamp;
        String value;
        Entry(int timestamp, String value) {
            this.timestamp = timestamp;
            this.value = value;
        }
    }

    private final Map<String, List<Entry>> values = new HashMap<>();

    public void set(String key, String value, int timestamp) {
        values.computeIfAbsent(key, unused -> new ArrayList<>())
              .add(new Entry(timestamp, value));
    }

    public String get(String key, int timestamp) {
        List<Entry> entries = values.get(key);
        if (entries == null) return "";
        int left = 0, right = entries.size() - 1, answer = -1;
        while (left <= right) {
            int mid = left + (right - left) / 2;
            if (entries.get(mid).timestamp <= timestamp) {
                answer = mid;
                left = mid + 1;
            } else {
                right = mid - 1;
            }
        }
        return answer == -1 ? "" : entries.get(answer).value;
    }
}
```

### 33. Median of Two Sorted Arrays (LC 4, Hard)

**Idea:** Binary-search a partition of the smaller array so both left partitions contain the lower half.  
**Time:** O(log(min(m, n))) **Space:** O(1)

```java
class Solution {
    public double findMedianSortedArrays(int[] nums1, int[] nums2) {
        if (nums1.length > nums2.length) return findMedianSortedArrays(nums2, nums1);
        int m = nums1.length, n = nums2.length;
        int leftSize = (m + n + 1) / 2;
        int low = 0, high = m;
        while (low <= high) {
            int cut1 = low + (high - low) / 2;
            int cut2 = leftSize - cut1;
            int left1 = cut1 == 0 ? Integer.MIN_VALUE : nums1[cut1 - 1];
            int right1 = cut1 == m ? Integer.MAX_VALUE : nums1[cut1];
            int left2 = cut2 == 0 ? Integer.MIN_VALUE : nums2[cut2 - 1];
            int right2 = cut2 == n ? Integer.MAX_VALUE : nums2[cut2];
            if (left1 <= right2 && left2 <= right1) {
                if (((m + n) & 1) == 1) return Math.max(left1, left2);
                return ((double) Math.max(left1, left2) + Math.min(right1, right2)) / 2.0;
            }
            if (left1 > right2) high = cut1 - 1;
            else low = cut1 + 1;
        }
        throw new IllegalArgumentException("Input arrays must be sorted");
    }
}
```

## Linked List

### 34. Reverse Linked List (LC 206, Easy)

**Idea:** Reverse each next pointer while walking the list once.  
**Time:** O(n) **Space:** O(1)

```java
class Solution {
    public ListNode reverseList(ListNode head) {
        ListNode previous = null;
        ListNode current = head;
        while (current != null) {
            ListNode next = current.next;
            current.next = previous;
            previous = current;
            current = next;
        }
        return previous;
    }
}
```

### 35. Merge Two Sorted Lists (LC 21, Easy)

**Idea:** Repeatedly append the smaller current node, then attach the remaining suffix.  
**Time:** O(m + n) **Space:** O(1)

```java
class Solution {
    public ListNode mergeTwoLists(ListNode list1, ListNode list2) {
        ListNode dummy = new ListNode(0), tail = dummy;
        while (list1 != null && list2 != null) {
            if (list1.val <= list2.val) {
                tail.next = list1;
                list1 = list1.next;
            } else {
                tail.next = list2;
                list2 = list2.next;
            }
            tail = tail.next;
        }
        tail.next = list1 != null ? list1 : list2;
        return dummy.next;
    }
}
```

### 36. Linked List Cycle (LC 141, Easy)

**Idea:** A slow pointer and a fast pointer meet exactly when a cycle exists.  
**Time:** O(n) **Space:** O(1)

```java
public class Solution {
    public boolean hasCycle(ListNode head) {
        ListNode slow = head, fast = head;
        while (fast != null && fast.next != null) {
            slow = slow.next;
            fast = fast.next.next;
            if (slow == fast) return true;
        }
        return false;
    }
}
```

### 37. Reorder List (LC 143, Medium)

**Idea:** Split at the middle, reverse the second half, then weave the two halves together.  
**Time:** O(n) **Space:** O(1)

```java
class Solution {
    public void reorderList(ListNode head) {
        if (head == null || head.next == null) return;

        ListNode slow = head, fast = head;
        while (fast.next != null && fast.next.next != null) {
            slow = slow.next;
            fast = fast.next.next;
        }

        ListNode second = slow.next;
        slow.next = null;
        ListNode previous = null;
        while (second != null) {
            ListNode next = second.next;
            second.next = previous;
            previous = second;
            second = next;
        }

        ListNode first = head;
        second = previous;
        while (second != null) {
            ListNode nextFirst = first.next;
            ListNode nextSecond = second.next;
            first.next = second;
            second.next = nextFirst;
            first = nextFirst;
            second = nextSecond;
        }
    }
}
```

### 38. Remove Nth Node From End of List (LC 19, Medium)

**Idea:** Advance one pointer `n` steps so the second pointer stops just before the target.  
**Time:** O(n) **Space:** O(1)

```java
class Solution {
    public ListNode removeNthFromEnd(ListNode head, int n) {
        ListNode dummy = new ListNode(0);
        dummy.next = head;
        ListNode fast = dummy, slow = dummy;
        for (int i = 0; i < n; i++) fast = fast.next;
        while (fast.next != null) {
            fast = fast.next;
            slow = slow.next;
        }
        slow.next = slow.next.next;
        return dummy.next;
    }
}
```

### 39. Copy List with Random Pointer (LC 138, Medium)

**Idea:** Interleave copied nodes with originals, assign random links through neighbors, then separate the lists.  
**Time:** O(n) **Space:** O(1) extra, excluding output

```java
class Solution {
    public Node copyRandomList(Node head) {
        if (head == null) return null;
        for (Node cur = head; cur != null; cur = cur.next.next) {
            Node copy = new Node(cur.val);
            copy.next = cur.next;
            cur.next = copy;
        }
        for (Node cur = head; cur != null; cur = cur.next.next) {
            if (cur.random != null) cur.next.random = cur.random.next;
        }
        Node copyHead = head.next;
        for (Node cur = head; cur != null;) {
            Node copy = cur.next;
            cur.next = copy.next;
            cur = cur.next;
            copy.next = cur == null ? null : cur.next;
        }
        return copyHead;
    }
}
```

### 40. Add Two Numbers (LC 2, Medium)

**Idea:** Add corresponding digits and carry exactly as in elementary addition.  
**Time:** O(max(m, n)) **Space:** O(max(m, n)) for the output

```java
class Solution {
    public ListNode addTwoNumbers(ListNode l1, ListNode l2) {
        ListNode dummy = new ListNode(0), tail = dummy;
        int carry = 0;
        while (l1 != null || l2 != null || carry != 0) {
            int sum = carry;
            if (l1 != null) {
                sum += l1.val;
                l1 = l1.next;
            }
            if (l2 != null) {
                sum += l2.val;
                l2 = l2.next;
            }
            tail.next = new ListNode(sum % 10);
            tail = tail.next;
            carry = sum / 10;
        }
        return dummy.next;
    }
}
```

### 41. Find the Duplicate Number (LC 287, Medium)

**Idea:** Treat values as next pointers and use Floyd's cycle algorithm to locate the cycle entrance.  
**Time:** O(n) **Space:** O(1)

```java
class Solution {
    public int findDuplicate(int[] nums) {
        int slow = nums[0], fast = nums[0];
        do {
            slow = nums[slow];
            fast = nums[nums[fast]];
        } while (slow != fast);

        slow = nums[0];
        while (slow != fast) {
            slow = nums[slow];
            fast = nums[fast];
        }
        return slow;
    }
}
```

### 42. LRU Cache (LC 146, Medium)

**Idea:** A hash map gives O(1) lookup while a doubly linked list keeps most-recently-used order.  
**Time:** O(1) average per operation **Space:** O(capacity)

```java
class LRUCache {
    private static class Entry {
        int key, value;
        Entry prev, next;
        Entry(int key, int value) { this.key = key; this.value = value; }
    }

    private final int capacity;
    private final Map<Integer, Entry> map = new HashMap<>();
    private final Entry head = new Entry(0, 0);
    private final Entry tail = new Entry(0, 0);

    public LRUCache(int capacity) {
        this.capacity = capacity;
        head.next = tail;
        tail.prev = head;
    }

    public int get(int key) {
        Entry node = map.get(key);
        if (node == null) return -1;
        moveToFront(node);
        return node.value;
    }

    public void put(int key, int value) {
        Entry node = map.get(key);
        if (node != null) {
            node.value = value;
            moveToFront(node);
            return;
        }
        node = new Entry(key, value);
        map.put(key, node);
        addFirst(node);
        if (map.size() > capacity) {
            Entry removed = tail.prev;
            unlink(removed);
            map.remove(removed.key);
        }
    }

    private void moveToFront(Entry node) {
        unlink(node);
        addFirst(node);
    }

    private void addFirst(Entry node) {
        node.next = head.next;
        node.prev = head;
        head.next.prev = node;
        head.next = node;
    }

    private void unlink(Entry node) {
        node.prev.next = node.next;
        node.next.prev = node.prev;
    }
}
```

### 43. Merge k Sorted Lists (LC 23, Hard)

**Idea:** A min-heap always exposes the smallest current head among the `k` lists.  
**Time:** O(N log k) **Space:** O(k)

```java
class Solution {
    public ListNode mergeKLists(ListNode[] lists) {
        PriorityQueue<ListNode> heap = new PriorityQueue<>(Comparator.comparingInt(node -> node.val));
        for (ListNode node : lists) if (node != null) heap.offer(node);
        ListNode dummy = new ListNode(0), tail = dummy;
        while (!heap.isEmpty()) {
            ListNode node = heap.poll();
            tail.next = node;
            tail = node;
            if (node.next != null) heap.offer(node.next);
        }
        return dummy.next;
    }
}
```

### 44. Reverse Nodes in k-Group (LC 25, Hard)

**Idea:** Locate each complete group of `k`, reverse it in place, and reconnect its boundaries.  
**Time:** O(n) **Space:** O(1)

```java
class Solution {
    public ListNode reverseKGroup(ListNode head, int k) {
        ListNode dummy = new ListNode(0);
        dummy.next = head;
        ListNode groupPrev = dummy;

        while (true) {
            ListNode kth = getKth(groupPrev, k);
            if (kth == null) break;
            ListNode groupNext = kth.next;
            ListNode prev = groupNext, cur = groupPrev.next;
            while (cur != groupNext) {
                ListNode next = cur.next;
                cur.next = prev;
                prev = cur;
                cur = next;
            }
            ListNode oldStart = groupPrev.next;
            groupPrev.next = kth;
            groupPrev = oldStart;
        }
        return dummy.next;
    }

    private ListNode getKth(ListNode node, int k) {
        while (node != null && k-- > 0) node = node.next;
        return node;
    }
}
```

## Trees

### 45. Invert Binary Tree (LC 226, Easy)

**Idea:** Recursively swap the inverted left and right subtrees.  
**Time:** O(n) **Space:** O(h)

```java
class Solution {
    public TreeNode invertTree(TreeNode root) {
        if (root == null) return null;
        TreeNode left = invertTree(root.left);
        root.left = invertTree(root.right);
        root.right = left;
        return root;
    }
}
```

### 46. Maximum Depth of Binary Tree (LC 104, Easy)

**Idea:** The depth is one plus the larger depth of the two subtrees.  
**Time:** O(n) **Space:** O(h)

```java
class Solution {
    public int maxDepth(TreeNode root) {
        if (root == null) return 0;
        return 1 + Math.max(maxDepth(root.left), maxDepth(root.right));
    }
}
```

### 47. Diameter of Binary Tree (LC 543, Easy)

**Idea:** A postorder DFS returns subtree height while updating the best path that passes through each node.  
**Time:** O(n) **Space:** O(h)

```java
class Solution {
    private int diameter = 0;

    public int diameterOfBinaryTree(TreeNode root) {
        height(root);
        return diameter;
    }

    private int height(TreeNode node) {
        if (node == null) return 0;
        int left = height(node.left);
        int right = height(node.right);
        diameter = Math.max(diameter, left + right);
        return 1 + Math.max(left, right);
    }
}
```

### 48. Balanced Binary Tree (LC 110, Easy)

**Idea:** Return -1 as a sentinel as soon as a subtree is unbalanced; otherwise return its height.  
**Time:** O(n) **Space:** O(h)

```java
class Solution {
    public boolean isBalanced(TreeNode root) {
        return height(root) != -1;
    }

    private int height(TreeNode node) {
        if (node == null) return 0;
        int left = height(node.left);
        if (left == -1) return -1;
        int right = height(node.right);
        if (right == -1 || Math.abs(left - right) > 1) return -1;
        return 1 + Math.max(left, right);
    }
}
```

### 49. Same Tree (LC 100, Easy)

**Idea:** Corresponding nodes must have equal values and recursively equal children.  
**Time:** O(n) **Space:** O(h)

```java
class Solution {
    public boolean isSameTree(TreeNode p, TreeNode q) {
        if (p == null || q == null) return p == q;
        return p.val == q.val && isSameTree(p.left, q.left) && isSameTree(p.right, q.right);
    }
}
```

### 50. Subtree of Another Tree (LC 572, Easy)

**Idea:** At every node with a matching value, test whether the two rooted trees are identical.  
**Time:** O(mn) worst case **Space:** O(h)

```java
class Solution {
    public boolean isSubtree(TreeNode root, TreeNode subRoot) {
        if (subRoot == null) return true;
        if (root == null) return false;
        return same(root, subRoot)
            || isSubtree(root.left, subRoot)
            || isSubtree(root.right, subRoot);
    }

    private boolean same(TreeNode a, TreeNode b) {
        if (a == null || b == null) return a == b;
        return a.val == b.val && same(a.left, b.left) && same(a.right, b.right);
    }
}
```

### 51. Lowest Common Ancestor of a Binary Search Tree (LC 235, Medium)

**Idea:** Use the BST ordering: move left when both targets are smaller and right when both are larger.  
**Time:** O(h) **Space:** O(1)

```java
class Solution {
    public TreeNode lowestCommonAncestor(TreeNode root, TreeNode p, TreeNode q) {
        int low = Math.min(p.val, q.val);
        int high = Math.max(p.val, q.val);
        while (root != null) {
            if (root.val < low) root = root.right;
            else if (root.val > high) root = root.left;
            else return root;
        }
        return null;
    }
}
```

### 52. Binary Tree Level Order Traversal (LC 102, Medium)

**Idea:** Process exactly the current queue size to collect one level at a time.  
**Time:** O(n) **Space:** O(n)

```java
class Solution {
    public List<List<Integer>> levelOrder(TreeNode root) {
        List<List<Integer>> ans = new ArrayList<>();
        if (root == null) return ans;
        Queue<TreeNode> queue = new ArrayDeque<>();
        queue.offer(root);
        while (!queue.isEmpty()) {
            int size = queue.size();
            List<Integer> level = new ArrayList<>(size);
            for (int i = 0; i < size; i++) {
                TreeNode node = queue.poll();
                level.add(node.val);
                if (node.left != null) queue.offer(node.left);
                if (node.right != null) queue.offer(node.right);
            }
            ans.add(level);
        }
        return ans;
    }
}
```

### 53. Binary Tree Right Side View (LC 199, Medium)

**Idea:** Traverse level by level and record the final node removed from each level.  
**Time:** O(n) **Space:** O(n)

```java
class Solution {
    public List<Integer> rightSideView(TreeNode root) {
        List<Integer> ans = new ArrayList<>();
        if (root == null) return ans;
        Queue<TreeNode> queue = new ArrayDeque<>();
        queue.offer(root);
        while (!queue.isEmpty()) {
            int size = queue.size();
            for (int i = 0; i < size; i++) {
                TreeNode node = queue.poll();
                if (i == size - 1) ans.add(node.val);
                if (node.left != null) queue.offer(node.left);
                if (node.right != null) queue.offer(node.right);
            }
        }
        return ans;
    }
}
```

### 54. Count Good Nodes in Binary Tree (LC 1448, Medium)

**Idea:** Carry the maximum value on the root-to-node path and count nodes that meet or exceed it.  
**Time:** O(n) **Space:** O(h)

```java
class Solution {
    public int goodNodes(TreeNode root) {
        return count(root, Integer.MIN_VALUE);
    }

    private int count(TreeNode node, int pathMaximum) {
        if (node == null) return 0;
        int good = node.val >= pathMaximum ? 1 : 0;
        int nextMaximum = Math.max(pathMaximum, node.val);
        return good + count(node.left, nextMaximum) + count(node.right, nextMaximum);
    }
}
```

### 55. Validate Binary Search Tree (LC 98, Medium)

**Idea:** Every node must lie strictly inside the valid range inherited from its ancestors.  
**Time:** O(n) **Space:** O(h)

```java
class Solution {
    public boolean isValidBST(TreeNode root) {
        return valid(root, Long.MIN_VALUE, Long.MAX_VALUE);
    }

    private boolean valid(TreeNode node, long low, long high) {
        if (node == null) return true;
        if (node.val <= low || node.val >= high) return false;
        return valid(node.left, low, node.val) && valid(node.right, node.val, high);
    }
}
```

### 56. Kth Smallest Element in a BST (LC 230, Medium)

**Idea:** Iterative inorder traversal produces BST values in ascending order.  
**Time:** O(h + k) **Space:** O(h)

```java
class Solution {
    public int kthSmallest(TreeNode root, int k) {
        Deque<TreeNode> stack = new ArrayDeque<>();
        while (true) {
            while (root != null) {
                stack.push(root);
                root = root.left;
            }
            root = stack.pop();
            if (--k == 0) return root.val;
            root = root.right;
        }
    }
}
```

### 57. Construct Binary Tree from Preorder and Inorder Traversal (LC 105, Medium)

**Idea:** Preorder chooses each root; an inorder index map splits the left and right subtrees.  
**Time:** O(n) **Space:** O(n)

```java
class Solution {
    private int preorderIndex;
    private Map<Integer, Integer> inorderIndex;

    public TreeNode buildTree(int[] preorder, int[] inorder) {
        inorderIndex = new HashMap<>();
        for (int i = 0; i < inorder.length; i++) inorderIndex.put(inorder[i], i);
        return build(preorder, 0, inorder.length - 1);
    }

    private TreeNode build(int[] preorder, int left, int right) {
        if (left > right) return null;
        int value = preorder[preorderIndex++];
        TreeNode root = new TreeNode(value);
        int mid = inorderIndex.get(value);
        root.left = build(preorder, left, mid - 1);
        root.right = build(preorder, mid + 1, right);
        return root;
    }
}
```

### 58. Binary Tree Maximum Path Sum (LC 124, Hard)

**Idea:** Each node returns its best one-sided gain while a global answer considers both child gains.  
**Time:** O(n) **Space:** O(h)

```java
class Solution {
    private int best = Integer.MIN_VALUE;

    public int maxPathSum(TreeNode root) {
        gain(root);
        return best;
    }

    private int gain(TreeNode node) {
        if (node == null) return 0;
        int left = Math.max(0, gain(node.left));
        int right = Math.max(0, gain(node.right));
        best = Math.max(best, node.val + left + right);
        return node.val + Math.max(left, right);
    }
}
```

### 59. Serialize and Deserialize Binary Tree (LC 297, Hard)

**Idea:** Serialize with preorder traversal and null markers, then consume the same token order recursively to rebuild the tree.  
**Time:** O(n) **Space:** O(n)

```java
class Codec {
    public String serialize(TreeNode root) {
        StringBuilder output = new StringBuilder();
        write(root, output);
        return output.toString();
    }

    private void write(TreeNode node, StringBuilder output) {
        if (node == null) {
            output.append("#,");
            return;
        }
        output.append(node.val).append(',');
        write(node.left, output);
        write(node.right, output);
    }

    public TreeNode deserialize(String data) {
        Deque<String> values = new ArrayDeque<>(Arrays.asList(data.split(",")));
        return read(values);
    }

    private TreeNode read(Deque<String> values) {
        String value = values.pollFirst();
        if (value.equals("#")) return null;
        TreeNode node = new TreeNode(Integer.parseInt(value));
        node.left = read(values);
        node.right = read(values);
        return node;
    }
}
```

## Heap / Priority Queue

### 60. Kth Largest Element in a Stream (LC 703, Easy)

**Idea:** Maintain a min-heap containing only the k largest values seen; its root is the kth largest.  
**Time:** O(log k) per add **Space:** O(k)

```java
class KthLargest {
    private final int k;
    private final PriorityQueue<Integer> heap = new PriorityQueue<>();

    public KthLargest(int k, int[] nums) {
        this.k = k;
        for (int value : nums) add(value);
    }

    public int add(int val) {
        heap.offer(val);
        if (heap.size() > k) heap.poll();
        return heap.peek();
    }
}
```

### 61. Last Stone Weight (LC 1046, Easy)

**Idea:** Repeatedly remove the two heaviest stones from a max-heap and reinsert their positive difference.  
**Time:** O(n log n) **Space:** O(n)

```java
class Solution {
    public int lastStoneWeight(int[] stones) {
        PriorityQueue<Integer> heap = new PriorityQueue<>(Comparator.reverseOrder());
        for (int stone : stones) heap.offer(stone);
        while (heap.size() > 1) {
            int first = heap.poll();
            int second = heap.poll();
            if (first != second) heap.offer(first - second);
        }
        return heap.isEmpty() ? 0 : heap.peek();
    }
}
```

### 62. K Closest Points to Origin (LC 973, Medium)

**Idea:** Keep a max-heap of the closest k points encountered, discarding the farthest whenever the heap grows.  
**Time:** O(n log k) **Space:** O(k)

```java
class Solution {
    public int[][] kClosest(int[][] points, int k) {
        PriorityQueue<int[]> heap = new PriorityQueue<>(
            (a, b) -> Long.compare(distance(b), distance(a))
        );
        for (int[] point : points) {
            heap.offer(point);
            if (heap.size() > k) heap.poll();
        }

        int[][] answer = new int[k][2];
        for (int i = 0; i < k; i++) answer[i] = heap.poll();
        return answer;
    }

    private long distance(int[] point) {
        return (long) point[0] * point[0] + (long) point[1] * point[1];
    }
}
```

### 63. Kth Largest Element in an Array (LC 215, Medium)

**Idea:** Keep a min-heap containing the largest `k` values seen so far.  
**Time:** O(n log k) **Space:** O(k)

```java
class Solution {
    public int findKthLargest(int[] nums, int k) {
        PriorityQueue<Integer> heap = new PriorityQueue<>();
        for (int value : nums) {
            heap.offer(value);
            if (heap.size() > k) heap.poll();
        }
        return heap.peek();
    }
}
```

### 64. Task Scheduler (LC 621, Medium)

**Idea:** Arrange the most frequent tasks as a frame; remaining tasks either fill the idle slots or extend the schedule.  
**Time:** O(n) **Space:** O(1)

```java
class Solution {
    public int leastInterval(char[] tasks, int n) {
        int[] frequency = new int[26];
        int maximum = 0;
        for (char task : tasks) maximum = Math.max(maximum, ++frequency[task - 'A']);

        int tiedForMaximum = 0;
        for (int count : frequency) {
            if (count == maximum) tiedForMaximum++;
        }
        int frame = (maximum - 1) * (n + 1) + tiedForMaximum;
        return Math.max(tasks.length, frame);
    }
}
```

### 65. Design Twitter (LC 355, Medium)

**Idea:** Store each user's tweets as a newest-first linked list and merge followed users' lists with a max-heap.  
**Time:** post/follow: O(1), feed: O((f + 10) log f) **Space:** O(t + f)

```java
class Twitter {
    private static class Tweet {
        int id;
        int time;
        Tweet next;
        Tweet(int id, int time, Tweet next) {
            this.id = id;
            this.time = time;
            this.next = next;
        }
    }

    private int clock = 0;
    private final Map<Integer, Tweet> tweets = new HashMap<>();
    private final Map<Integer, Set<Integer>> follows = new HashMap<>();

    public void postTweet(int userId, int tweetId) {
        tweets.put(userId, new Tweet(tweetId, clock++, tweets.get(userId)));
    }

    public List<Integer> getNewsFeed(int userId) {
        Set<Integer> users = new HashSet<>(follows.getOrDefault(userId, Collections.emptySet()));
        users.add(userId);
        PriorityQueue<Tweet> heap = new PriorityQueue<>((a, b) -> Integer.compare(b.time, a.time));
        for (int user : users) {
            Tweet head = tweets.get(user);
            if (head != null) heap.offer(head);
        }

        List<Integer> feed = new ArrayList<>();
        while (!heap.isEmpty() && feed.size() < 10) {
            Tweet tweet = heap.poll();
            feed.add(tweet.id);
            if (tweet.next != null) heap.offer(tweet.next);
        }
        return feed;
    }

    public void follow(int followerId, int followeeId) {
        if (followerId != followeeId) {
            follows.computeIfAbsent(followerId, unused -> new HashSet<>()).add(followeeId);
        }
    }

    public void unfollow(int followerId, int followeeId) {
        Set<Integer> followed = follows.get(followerId);
        if (followed != null) followed.remove(followeeId);
    }
}
```

### 66. Find Median from Data Stream (LC 295, Hard)

**Idea:** Balance a max-heap for the lower half and a min-heap for the upper half.  
**Time:** O(log n) per insertion, O(1) per median **Space:** O(n)

```java
class MedianFinder {
    private final PriorityQueue<Integer> lower = new PriorityQueue<>(Collections.reverseOrder());
    private final PriorityQueue<Integer> upper = new PriorityQueue<>();

    public MedianFinder() {}

    public void addNum(int num) {
        lower.offer(num);
        upper.offer(lower.poll());
        if (upper.size() > lower.size()) lower.offer(upper.poll());
    }

    public double findMedian() {
        if (lower.size() > upper.size()) return lower.peek();
        return ((double) lower.peek() + upper.peek()) / 2.0;
    }
}
```

## Backtracking

### 67. Subsets (LC 78, Medium)

**Idea:** Explore the include/exclude choice for every value and record each completed subset.  
**Time:** O(n * 2^n) **Space:** O(n) excluding output

```java
class Solution {
    public List<List<Integer>> subsets(int[] nums) {
        List<List<Integer>> answer = new ArrayList<>();
        build(nums, 0, new ArrayList<>(), answer);
        return answer;
    }

    private void build(int[] nums, int index, List<Integer> path,
                       List<List<Integer>> answer) {
        if (index == nums.length) {
            answer.add(new ArrayList<>(path));
            return;
        }
        build(nums, index + 1, path, answer);
        path.add(nums[index]);
        build(nums, index + 1, path, answer);
        path.remove(path.size() - 1);
    }
}
```

### 68. Combination Sum (LC 39, Medium)

**Idea:** Sort candidates and backtrack with the current index unchanged to allow reuse.  
**Time:** Proportional to the number of explored combinations **Space:** O(target / minimum candidate)

```java
class Solution {
    public List<List<Integer>> combinationSum(int[] candidates, int target) {
        Arrays.sort(candidates);
        List<List<Integer>> ans = new ArrayList<>();
        build(candidates, target, 0, new ArrayList<>(), ans);
        return ans;
    }

    private void build(int[] candidates, int remain, int start,
                       List<Integer> path, List<List<Integer>> ans) {
        if (remain == 0) {
            ans.add(new ArrayList<>(path));
            return;
        }
        for (int i = start; i < candidates.length && candidates[i] <= remain; i++) {
            path.add(candidates[i]);
            build(candidates, remain - candidates[i], i, path, ans);
            path.remove(path.size() - 1);
        }
    }
}
```

### 69. Combination Sum II (LC 40, Medium)

**Idea:** Sort candidates, choose each index at most once, and skip duplicate choices at the same depth.  
**Time:** O(2^n) **Space:** O(n) excluding output

```java
class Solution {
    public List<List<Integer>> combinationSum2(int[] candidates, int target) {
        Arrays.sort(candidates);
        List<List<Integer>> answer = new ArrayList<>();
        search(candidates, 0, target, new ArrayList<>(), answer);
        return answer;
    }

    private void search(int[] candidates, int start, int remaining,
                        List<Integer> path, List<List<Integer>> answer) {
        if (remaining == 0) {
            answer.add(new ArrayList<>(path));
            return;
        }
        for (int i = start; i < candidates.length && candidates[i] <= remaining; i++) {
            if (i > start && candidates[i] == candidates[i - 1]) continue;
            path.add(candidates[i]);
            search(candidates, i + 1, remaining - candidates[i], path, answer);
            path.remove(path.size() - 1);
        }
    }
}
```

### 70. Permutations (LC 46, Medium)

**Idea:** At each position, swap every remaining value into that position and undo the swap afterward.  
**Time:** O(n * n!) **Space:** O(n)

```java
class Solution {
    public List<List<Integer>> permute(int[] nums) {
        List<List<Integer>> ans = new ArrayList<>();
        build(nums, 0, ans);
        return ans;
    }

    private void build(int[] nums, int index, List<List<Integer>> ans) {
        if (index == nums.length) {
            List<Integer> permutation = new ArrayList<>();
            for (int x : nums) permutation.add(x);
            ans.add(permutation);
            return;
        }
        for (int i = index; i < nums.length; i++) {
            swap(nums, index, i);
            build(nums, index + 1, ans);
            swap(nums, index, i);
        }
    }

    private void swap(int[] nums, int i, int j) {
        int tmp = nums[i];
        nums[i] = nums[j];
        nums[j] = tmp;
    }
}
```

### 71. Subsets II (LC 90, Medium)

**Idea:** Sort first, then skip equal choices made at the same recursion depth.  
**Time:** O(n * 2^n) **Space:** O(n) excluding output

```java
class Solution {
    public List<List<Integer>> subsetsWithDup(int[] nums) {
        Arrays.sort(nums);
        List<List<Integer>> answer = new ArrayList<>();
        backtrack(nums, 0, new ArrayList<>(), answer);
        return answer;
    }

    private void backtrack(int[] nums, int start, List<Integer> path,
                           List<List<Integer>> answer) {
        answer.add(new ArrayList<>(path));
        for (int i = start; i < nums.length; i++) {
            if (i > start && nums[i] == nums[i - 1]) continue;
            path.add(nums[i]);
            backtrack(nums, i + 1, path, answer);
            path.remove(path.size() - 1);
        }
    }
}
```

### 72. Generate Parentheses (LC 22, Medium)

**Idea:** Add `(` while available and add `)` only when it cannot make the prefix invalid.  
**Time:** O(C_n * n), where C_n is the nth Catalan number **Space:** O(n)

```java
class Solution {
    public List<String> generateParenthesis(int n) {
        List<String> ans = new ArrayList<>();
        build(n, 0, 0, new StringBuilder(), ans);
        return ans;
    }

    private void build(int n, int open, int close, StringBuilder path, List<String> ans) {
        if (path.length() == 2 * n) {
            ans.add(path.toString());
            return;
        }
        if (open < n) {
            path.append('(');
            build(n, open + 1, close, path, ans);
            path.deleteCharAt(path.length() - 1);
        }
        if (close < open) {
            path.append(')');
            build(n, open, close + 1, path, ans);
            path.deleteCharAt(path.length() - 1);
        }
    }
}
```

### 73. Word Search (LC 79, Medium)

**Idea:** Start DFS from every matching cell, temporarily marking used cells during the current path.  
**Time:** O(mn * 4^L) **Space:** O(L)

```java
class Solution {
    public boolean exist(char[][] board, String word) {
        for (int r = 0; r < board.length; r++) {
            for (int c = 0; c < board[0].length; c++) {
                if (search(board, word, 0, r, c)) return true;
            }
        }
        return false;
    }

    private boolean search(char[][] board, String word, int index, int r, int c) {
        if (index == word.length()) return true;
        if (r < 0 || r == board.length || c < 0 || c == board[0].length
                || board[r][c] != word.charAt(index)) return false;
        char saved = board[r][c];
        board[r][c] = '#';
        boolean found = search(board, word, index + 1, r + 1, c)
                || search(board, word, index + 1, r - 1, c)
                || search(board, word, index + 1, r, c + 1)
                || search(board, word, index + 1, r, c - 1);
        board[r][c] = saved;
        return found;
    }
}
```

### 74. Palindrome Partitioning (LC 131, Medium)

**Idea:** Backtrack over every palindromic prefix and continue partitioning the remaining suffix.  
**Time:** O(n^2 * 2^n) **Space:** O(n) excluding output

```java
class Solution {
    public List<List<String>> partition(String s) {
        List<List<String>> answer = new ArrayList<>();
        search(s, 0, new ArrayList<>(), answer);
        return answer;
    }

    private void search(String s, int start, List<String> path,
                        List<List<String>> answer) {
        if (start == s.length()) {
            answer.add(new ArrayList<>(path));
            return;
        }
        for (int end = start; end < s.length(); end++) {
            if (!isPalindrome(s, start, end)) continue;
            path.add(s.substring(start, end + 1));
            search(s, end + 1, path, answer);
            path.remove(path.size() - 1);
        }
    }

    private boolean isPalindrome(String s, int left, int right) {
        while (left < right) {
            if (s.charAt(left++) != s.charAt(right--)) return false;
        }
        return true;
    }
}
```

### 75. Letter Combinations of a Phone Number (LC 17, Medium)

**Idea:** Choose one mapped letter for each digit and backtrack after every recursive call.  
**Time:** O(4^n * n) **Space:** O(n)

```java
class Solution {
    private static final String[] MAP = {
        "", "", "abc", "def", "ghi", "jkl", "mno", "pqrs", "tuv", "wxyz"
    };

    public List<String> letterCombinations(String digits) {
        List<String> ans = new ArrayList<>();
        if (digits.isEmpty()) return ans;
        build(digits, 0, new StringBuilder(), ans);
        return ans;
    }

    private void build(String digits, int index, StringBuilder path, List<String> ans) {
        if (index == digits.length()) {
            ans.add(path.toString());
            return;
        }
        for (char c : MAP[digits.charAt(index) - '0'].toCharArray()) {
            path.append(c);
            build(digits, index + 1, path, ans);
            path.deleteCharAt(path.length() - 1);
        }
    }
}
```

### 76. N-Queens (LC 51, Hard)

**Idea:** Place one queen per row while tracking occupied columns and diagonals.  
**Time:** O(n!) **Space:** O(n^2) including the board

```java
class Solution {
    public List<List<String>> solveNQueens(int n) {
        List<List<String>> answer = new ArrayList<>();
        char[][] board = new char[n][n];
        for (char[] row : board) Arrays.fill(row, '.');
        place(0, board, new boolean[n], new boolean[2 * n],
              new boolean[2 * n], answer);
        return answer;
    }

    private void place(int row, char[][] board, boolean[] columns,
                       boolean[] diagonalDown, boolean[] diagonalUp,
                       List<List<String>> answer) {
        int n = board.length;
        if (row == n) {
            List<String> solution = new ArrayList<>();
            for (char[] line : board) solution.add(new String(line));
            answer.add(solution);
            return;
        }

        for (int column = 0; column < n; column++) {
            int down = row - column + n;
            int up = row + column;
            if (columns[column] || diagonalDown[down] || diagonalUp[up]) continue;
            columns[column] = diagonalDown[down] = diagonalUp[up] = true;
            board[row][column] = 'Q';
            place(row + 1, board, columns, diagonalDown, diagonalUp, answer);
            board[row][column] = '.';
            columns[column] = diagonalDown[down] = diagonalUp[up] = false;
        }
    }
}
```

## Tries

### 77. Implement Trie (Prefix Tree) (LC 208, Medium)

**Idea:** Each node stores one child per lowercase letter and an end-of-word flag.  
**Time:** O(L) per operation **Space:** O(total inserted characters)

```java
class Trie {
    private static class TrieNode {
        TrieNode[] next = new TrieNode[26];
        boolean word;
    }

    private final TrieNode root = new TrieNode();

    public Trie() {}

    public void insert(String word) {
        TrieNode node = root;
        for (char c : word.toCharArray()) {
            int i = c - 'a';
            if (node.next[i] == null) node.next[i] = new TrieNode();
            node = node.next[i];
        }
        node.word = true;
    }

    public boolean search(String word) {
        TrieNode node = walk(word);
        return node != null && node.word;
    }

    public boolean startsWith(String prefix) {
        return walk(prefix) != null;
    }

    private TrieNode walk(String s) {
        TrieNode node = root;
        for (char c : s.toCharArray()) {
            node = node.next[c - 'a'];
            if (node == null) return null;
        }
        return node;
    }
}
```

### 78. Design Add and Search Words Data Structure (LC 211, Medium)

**Idea:** Use a trie; during search, `.` recursively explores every available child.  
**Time:** O(L) without wildcards, exponential in the number of wildcards worst case **Space:** O(total inserted characters)

```java
class WordDictionary {
    private static class TrieNode {
        TrieNode[] next = new TrieNode[26];
        boolean word;
    }

    private final TrieNode root = new TrieNode();

    public WordDictionary() {}

    public void addWord(String word) {
        TrieNode node = root;
        for (char c : word.toCharArray()) {
            int i = c - 'a';
            if (node.next[i] == null) node.next[i] = new TrieNode();
            node = node.next[i];
        }
        node.word = true;
    }

    public boolean search(String word) {
        return search(word, 0, root);
    }

    private boolean search(String word, int index, TrieNode node) {
        if (index == word.length()) return node.word;
        char c = word.charAt(index);
        if (c != '.') {
            TrieNode next = node.next[c - 'a'];
            return next != null && search(word, index + 1, next);
        }
        for (TrieNode next : node.next) {
            if (next != null && search(word, index + 1, next)) return true;
        }
        return false;
    }
}
```

### 79. Word Search II (LC 212, Hard)

**Idea:** Build a trie of all words, then DFS the board while pruning paths absent from the trie.  
**Time:** O(mn * 4^L) worst case **Space:** O(total word characters + L)

```java
class Solution {
    private static class TrieNode {
        TrieNode[] next = new TrieNode[26];
        String word;
    }

    public List<String> findWords(char[][] board, String[] words) {
        TrieNode root = new TrieNode();
        for (String word : words) insert(root, word);
        List<String> ans = new ArrayList<>();
        for (int r = 0; r < board.length; r++) {
            for (int c = 0; c < board[0].length; c++) dfs(board, r, c, root, ans);
        }
        return ans;
    }

    private void insert(TrieNode root, String word) {
        TrieNode node = root;
        for (char c : word.toCharArray()) {
            int i = c - 'a';
            if (node.next[i] == null) node.next[i] = new TrieNode();
            node = node.next[i];
        }
        node.word = word;
    }

    private void dfs(char[][] board, int r, int c, TrieNode node, List<String> ans) {
        if (r < 0 || r == board.length || c < 0 || c == board[0].length || board[r][c] == '#') return;
        char ch = board[r][c];
        TrieNode next = node.next[ch - 'a'];
        if (next == null) return;
        if (next.word != null) {
            ans.add(next.word);
            next.word = null;
        }
        board[r][c] = '#';
        dfs(board, r + 1, c, next, ans);
        dfs(board, r - 1, c, next, ans);
        dfs(board, r, c + 1, next, ans);
        dfs(board, r, c - 1, next, ans);
        board[r][c] = ch;
    }
}
```

## Graphs

### 80. Number of Islands (LC 200, Medium)

**Idea:** Every unvisited land cell starts one island; DFS marks its whole connected component.  
**Time:** O(mn) **Space:** O(mn)

```java
class Solution {
    private static final int[][] DIRS = {{1, 0}, {-1, 0}, {0, 1}, {0, -1}};

    public int numIslands(char[][] grid) {
        int islands = 0;
        for (int r = 0; r < grid.length; r++) {
            for (int c = 0; c < grid[0].length; c++) {
                if (grid[r][c] != '1') continue;
                islands++;
                flood(grid, r, c);
            }
        }
        return islands;
    }

    private void flood(char[][] grid, int startRow, int startCol) {
        Deque<int[]> stack = new ArrayDeque<>();
        stack.push(new int[]{startRow, startCol});
        grid[startRow][startCol] = '0';
        while (!stack.isEmpty()) {
            int[] cell = stack.pop();
            for (int[] dir : DIRS) {
                int r = cell[0] + dir[0], c = cell[1] + dir[1];
                if (r >= 0 && r < grid.length && c >= 0 && c < grid[0].length
                        && grid[r][c] == '1') {
                    grid[r][c] = '0';
                    stack.push(new int[]{r, c});
                }
            }
        }
    }
}
```

### 81. Max Area of Island (LC 695, Medium)

**Idea:** Start DFS from every unvisited land cell, erase the component, and return its accumulated area.  
**Time:** O(mn) **Space:** O(mn) worst-case recursion

```java
class Solution {
    public int maxAreaOfIsland(int[][] grid) {
        int best = 0;
        for (int row = 0; row < grid.length; row++) {
            for (int column = 0; column < grid[0].length; column++) {
                best = Math.max(best, area(grid, row, column));
            }
        }
        return best;
    }

    private int area(int[][] grid, int row, int column) {
        if (row < 0 || row == grid.length || column < 0 || column == grid[0].length
                || grid[row][column] == 0) return 0;
        grid[row][column] = 0;
        return 1 + area(grid, row + 1, column) + area(grid, row - 1, column)
                 + area(grid, row, column + 1) + area(grid, row, column - 1);
    }
}
```

### 82. Clone Graph (LC 133, Medium)

**Idea:** Memoize each copied node before recursively cloning its neighbors.  
**Time:** O(V + E) **Space:** O(V)

```java
class Solution {
    private final Map<Node, Node> copies = new HashMap<>();

    public Node cloneGraph(Node node) {
        if (node == null) return null;
        if (copies.containsKey(node)) return copies.get(node);
        Node copy = new Node(node.val);
        copies.put(node, copy);
        for (Node neighbor : node.neighbors) copy.neighbors.add(cloneGraph(neighbor));
        return copy;
    }
}
```

### 83. Walls and Gates (LC 286, Medium, Premium)

**Idea:** Start BFS from every gate simultaneously so each empty room receives its shortest distance first.  
**Time:** O(mn) **Space:** O(mn)

```java
class Solution {
    public void wallsAndGates(int[][] rooms) {
        Queue<int[]> queue = new ArrayDeque<>();
        for (int row = 0; row < rooms.length; row++) {
            for (int column = 0; column < rooms[0].length; column++) {
                if (rooms[row][column] == 0) queue.offer(new int[]{row, column});
            }
        }

        int[][] directions = {{1, 0}, {-1, 0}, {0, 1}, {0, -1}};
        while (!queue.isEmpty()) {
            int[] cell = queue.poll();
            for (int[] direction : directions) {
                int row = cell[0] + direction[0];
                int column = cell[1] + direction[1];
                if (row < 0 || row == rooms.length || column < 0
                        || column == rooms[0].length || rooms[row][column] != Integer.MAX_VALUE) continue;
                rooms[row][column] = rooms[cell[0]][cell[1]] + 1;
                queue.offer(new int[]{row, column});
            }
        }
    }
}
```

### 84. Rotting Oranges (LC 994, Medium)

**Idea:** Run multi-source BFS from all rotten oranges and count layers until no fresh orange remains.  
**Time:** O(mn) **Space:** O(mn)

```java
class Solution {
    public int orangesRotting(int[][] grid) {
        Queue<int[]> queue = new ArrayDeque<>();
        int fresh = 0;
        for (int row = 0; row < grid.length; row++) {
            for (int column = 0; column < grid[0].length; column++) {
                if (grid[row][column] == 2) queue.offer(new int[]{row, column});
                else if (grid[row][column] == 1) fresh++;
            }
        }

        int minutes = 0;
        int[][] directions = {{1, 0}, {-1, 0}, {0, 1}, {0, -1}};
        while (!queue.isEmpty() && fresh > 0) {
            for (int size = queue.size(); size > 0; size--) {
                int[] cell = queue.poll();
                for (int[] direction : directions) {
                    int row = cell[0] + direction[0];
                    int column = cell[1] + direction[1];
                    if (row < 0 || row == grid.length || column < 0
                            || column == grid[0].length || grid[row][column] != 1) continue;
                    grid[row][column] = 2;
                    fresh--;
                    queue.offer(new int[]{row, column});
                }
            }
            minutes++;
        }
        return fresh == 0 ? minutes : -1;
    }
}
```

### 85. Pacific Atlantic Water Flow (LC 417, Medium)

**Idea:** Reverse the flow: mark cells reachable uphill from each ocean's border, then intersect the markings.  
**Time:** O(mn) **Space:** O(mn)

```java
class Solution {
    private static final int[][] DIRECTIONS = {{1, 0}, {-1, 0}, {0, 1}, {0, -1}};

    public List<List<Integer>> pacificAtlantic(int[][] heights) {
        int rows = heights.length, columns = heights[0].length;
        boolean[][] pacific = new boolean[rows][columns];
        boolean[][] atlantic = new boolean[rows][columns];

        for (int row = 0; row < rows; row++) {
            flow(heights, pacific, row, 0);
            flow(heights, atlantic, row, columns - 1);
        }
        for (int column = 0; column < columns; column++) {
            flow(heights, pacific, 0, column);
            flow(heights, atlantic, rows - 1, column);
        }

        List<List<Integer>> answer = new ArrayList<>();
        for (int row = 0; row < rows; row++) {
            for (int column = 0; column < columns; column++) {
                if (pacific[row][column] && atlantic[row][column]) {
                    answer.add(Arrays.asList(row, column));
                }
            }
        }
        return answer;
    }

    private void flow(int[][] heights, boolean[][] reached, int startRow, int startColumn) {
        Deque<int[]> stack = new ArrayDeque<>();
        stack.push(new int[]{startRow, startColumn});
        reached[startRow][startColumn] = true;
        while (!stack.isEmpty()) {
            int[] cell = stack.pop();
            for (int[] direction : DIRECTIONS) {
                int row = cell[0] + direction[0];
                int column = cell[1] + direction[1];
                if (row < 0 || row == heights.length || column < 0
                        || column == heights[0].length || reached[row][column]
                        || heights[row][column] < heights[cell[0]][cell[1]]) continue;
                reached[row][column] = true;
                stack.push(new int[]{row, column});
            }
        }
    }
}
```

### 86. Surrounded Regions (LC 130, Medium)

**Idea:** Boundary-connected `O` cells cannot be captured; mark them first, flip the rest, then restore the marks.  
**Time:** O(mn) **Space:** O(mn)

```java
class Solution {
    private static final int[][] DIRS = {{1, 0}, {-1, 0}, {0, 1}, {0, -1}};

    public void solve(char[][] board) {
        int rows = board.length, cols = board[0].length;
        Queue<int[]> queue = new ArrayDeque<>();
        for (int r = 0; r < rows; r++) {
            addBoundary(board, r, 0, queue);
            addBoundary(board, r, cols - 1, queue);
        }
        for (int c = 0; c < cols; c++) {
            addBoundary(board, 0, c, queue);
            addBoundary(board, rows - 1, c, queue);
        }
        while (!queue.isEmpty()) {
            int[] cell = queue.poll();
            for (int[] dir : DIRS) {
                addBoundary(board, cell[0] + dir[0], cell[1] + dir[1], queue);
            }
        }
        for (int r = 0; r < rows; r++) {
            for (int c = 0; c < cols; c++) {
                if (board[r][c] == 'O') board[r][c] = 'X';
                else if (board[r][c] == '#') board[r][c] = 'O';
            }
        }
    }

    private void addBoundary(char[][] board, int r, int c, Queue<int[]> queue) {
        if (r < 0 || r >= board.length || c < 0 || c >= board[0].length
                || board[r][c] != 'O') return;
        board[r][c] = '#';
        queue.offer(new int[]{r, c});
    }
}
```

### 87. Course Schedule (LC 207, Medium)

**Idea:** Kahn's algorithm repeatedly removes zero-indegree courses; all courses must be removed.  
**Time:** O(V + E) **Space:** O(V + E)

```java
class Solution {
    public boolean canFinish(int numCourses, int[][] prerequisites) {
        List<Integer>[] graph = new ArrayList[numCourses];
        for (int i = 0; i < numCourses; i++) graph[i] = new ArrayList<>();
        int[] indegree = new int[numCourses];
        for (int[] edge : prerequisites) {
            graph[edge[1]].add(edge[0]);
            indegree[edge[0]]++;
        }
        Queue<Integer> queue = new ArrayDeque<>();
        for (int i = 0; i < numCourses; i++) if (indegree[i] == 0) queue.offer(i);
        int taken = 0;
        while (!queue.isEmpty()) {
            int course = queue.poll();
            taken++;
            for (int next : graph[course]) if (--indegree[next] == 0) queue.offer(next);
        }
        return taken == numCourses;
    }
}
```

### 88. Course Schedule II (LC 210, Medium)

**Idea:** Record the zero-indegree removal order; a complete order exists only if every course is processed.  
**Time:** O(V + E) **Space:** O(V + E)

```java
class Solution {
    public int[] findOrder(int numCourses, int[][] prerequisites) {
        List<Integer>[] graph = new ArrayList[numCourses];
        for (int i = 0; i < numCourses; i++) graph[i] = new ArrayList<>();
        int[] indegree = new int[numCourses];
        for (int[] edge : prerequisites) {
            graph[edge[1]].add(edge[0]);
            indegree[edge[0]]++;
        }
        Queue<Integer> queue = new ArrayDeque<>();
        for (int i = 0; i < numCourses; i++) if (indegree[i] == 0) queue.offer(i);
        int[] order = new int[numCourses];
        int index = 0;
        while (!queue.isEmpty()) {
            int course = queue.poll();
            order[index++] = course;
            for (int next : graph[course]) if (--indegree[next] == 0) queue.offer(next);
        }
        return index == numCourses ? order : new int[0];
    }
}
```

### 89. Graph Valid Tree (LC 261, Medium, Premium)

**Idea:** A tree must have exactly n - 1 edges; union-find then verifies that no edge creates a cycle.  
**Time:** O(n alpha(n)) **Space:** O(n)

```java
class Solution {
    public boolean validTree(int n, int[][] edges) {
        if (edges.length != n - 1) return false;
        int[] parent = new int[n];
        int[] rank = new int[n];
        for (int i = 0; i < n; i++) parent[i] = i;

        for (int[] edge : edges) {
            int a = find(parent, edge[0]);
            int b = find(parent, edge[1]);
            if (a == b) return false;
            if (rank[a] < rank[b]) parent[a] = b;
            else if (rank[a] > rank[b]) parent[b] = a;
            else {
                parent[b] = a;
                rank[a]++;
            }
        }
        return true;
    }

    private int find(int[] parent, int node) {
        if (parent[node] != node) parent[node] = find(parent, parent[node]);
        return parent[node];
    }
}
```

### 90. Number of Connected Components in an Undirected Graph (LC 323, Medium, Premium)

**Idea:** Start with n components and decrement the count whenever a union joins two previously separate sets.  
**Time:** O((n + e) alpha(n)) **Space:** O(n)

```java
class Solution {
    public int countComponents(int n, int[][] edges) {
        int[] parent = new int[n];
        int[] size = new int[n];
        for (int i = 0; i < n; i++) {
            parent[i] = i;
            size[i] = 1;
        }

        int components = n;
        for (int[] edge : edges) {
            int a = find(parent, edge[0]);
            int b = find(parent, edge[1]);
            if (a == b) continue;
            if (size[a] < size[b]) {
                int temporary = a;
                a = b;
                b = temporary;
            }
            parent[b] = a;
            size[a] += size[b];
            components--;
        }
        return components;
    }

    private int find(int[] parent, int node) {
        while (node != parent[node]) {
            parent[node] = parent[parent[node]];
            node = parent[node];
        }
        return node;
    }
}
```

### 91. Redundant Connection (LC 684, Medium)

**Idea:** Union endpoints in order; the first edge whose endpoints are already connected is redundant.  
**Time:** O(n alpha(n)) **Space:** O(n)

```java
class Solution {
    public int[] findRedundantConnection(int[][] edges) {
        int[] parent = new int[edges.length + 1];
        int[] rank = new int[parent.length];
        for (int i = 0; i < parent.length; i++) parent[i] = i;

        for (int[] edge : edges) {
            int a = find(parent, edge[0]);
            int b = find(parent, edge[1]);
            if (a == b) return edge;
            if (rank[a] < rank[b]) parent[a] = b;
            else if (rank[a] > rank[b]) parent[b] = a;
            else {
                parent[b] = a;
                rank[a]++;
            }
        }
        return new int[0];
    }

    private int find(int[] parent, int node) {
        if (parent[node] != node) parent[node] = find(parent, parent[node]);
        return parent[node];
    }
}
```

### 92. Word Ladder (LC 127, Hard)

**Idea:** BFS through dictionary words that differ by one character, removing each word when first visited.  
**Time:** O(N * L * 26) **Space:** O(N * L)

```java
class Solution {
    public int ladderLength(String beginWord, String endWord, List<String> wordList) {
        Set<String> remaining = new HashSet<>(wordList);
        if (!remaining.contains(endWord)) return 0;
        Queue<String> queue = new ArrayDeque<>();
        queue.offer(beginWord);
        remaining.remove(beginWord);
        int length = 1;

        while (!queue.isEmpty()) {
            for (int size = queue.size(); size > 0; size--) {
                String word = queue.poll();
                if (word.equals(endWord)) return length;
                char[] chars = word.toCharArray();
                for (int i = 0; i < chars.length; i++) {
                    char original = chars[i];
                    for (char c = 'a'; c <= 'z'; c++) {
                        if (c == original) continue;
                        chars[i] = c;
                        String next = new String(chars);
                        if (remaining.remove(next)) queue.offer(next);
                    }
                    chars[i] = original;
                }
            }
            length++;
        }
        return 0;
    }
}
```

## Advanced Graphs

### 93. Network Delay Time (LC 743, Medium)

**Idea:** Run Dijkstra from k; the answer is the largest finalized shortest-path distance if every node is reached.  
**Time:** O((V + E) log V) **Space:** O(V + E)

```java
class Solution {
    public int networkDelayTime(int[][] times, int n, int k) {
        List<int[]>[] graph = new List[n + 1];
        for (int i = 1; i <= n; i++) graph[i] = new ArrayList<>();
        for (int[] edge : times) graph[edge[0]].add(new int[]{edge[1], edge[2]});

        int[] distance = new int[n + 1];
        Arrays.fill(distance, Integer.MAX_VALUE);
        distance[k] = 0;
        PriorityQueue<int[]> heap = new PriorityQueue<>(Comparator.comparingInt(a -> a[0]));
        heap.offer(new int[]{0, k});

        while (!heap.isEmpty()) {
            int[] state = heap.poll();
            int elapsed = state[0], node = state[1];
            if (elapsed != distance[node]) continue;
            for (int[] edge : graph[node]) {
                int next = edge[0], candidate = elapsed + edge[1];
                if (candidate < distance[next]) {
                    distance[next] = candidate;
                    heap.offer(new int[]{candidate, next});
                }
            }
        }

        int answer = 0;
        for (int node = 1; node <= n; node++) {
            if (distance[node] == Integer.MAX_VALUE) return -1;
            answer = Math.max(answer, distance[node]);
        }
        return answer;
    }
}
```

### 94. Reconstruct Itinerary (LC 332, Hard)

**Idea:** Use Hierholzer's algorithm with lexical min-heaps and append airports after exhausting outgoing edges.  
**Time:** O(E log E) **Space:** O(E)

```java
class Solution {
    public List<String> findItinerary(List<List<String>> tickets) {
        Map<String, PriorityQueue<String>> graph = new HashMap<>();
        for (List<String> ticket : tickets) {
            graph.computeIfAbsent(ticket.get(0), unused -> new PriorityQueue<>())
                 .offer(ticket.get(1));
        }
        LinkedList<String> route = new LinkedList<>();
        visit("JFK", graph, route);
        return route;
    }

    private void visit(String airport, Map<String, PriorityQueue<String>> graph,
                       LinkedList<String> route) {
        PriorityQueue<String> destinations = graph.get(airport);
        while (destinations != null && !destinations.isEmpty()) {
            visit(destinations.poll(), graph, route);
        }
        route.addFirst(airport);
    }
}
```

### 95. Min Cost to Connect All Points (LC 1584, Medium)

**Idea:** Run dense Prim's algorithm, repeatedly adding the closest unused point and relaxing Manhattan distances.  
**Time:** O(n^2) **Space:** O(n)

```java
class Solution {
    public int minCostConnectPoints(int[][] points) {
        int n = points.length;
        int[] distance = new int[n];
        Arrays.fill(distance, Integer.MAX_VALUE);
        boolean[] used = new boolean[n];
        distance[0] = 0;
        int cost = 0;

        for (int count = 0; count < n; count++) {
            int next = -1;
            for (int i = 0; i < n; i++) {
                if (!used[i] && (next == -1 || distance[i] < distance[next])) next = i;
            }
            used[next] = true;
            cost += distance[next];

            for (int i = 0; i < n; i++) {
                if (!used[i]) {
                    int candidate = Math.abs(points[next][0] - points[i][0])
                                  + Math.abs(points[next][1] - points[i][1]);
                    distance[i] = Math.min(distance[i], candidate);
                }
            }
        }
        return cost;
    }
}
```

### 96. Swim in Rising Water (LC 778, Hard)

**Idea:** Use Dijkstra where a path's cost is the highest elevation encountered; stop when the destination is finalized.  
**Time:** O(n^2 log n) **Space:** O(n^2)

```java
class Solution {
    public int swimInWater(int[][] grid) {
        int n = grid.length;
        int[][] best = new int[n][n];
        for (int[] row : best) Arrays.fill(row, Integer.MAX_VALUE);
        PriorityQueue<int[]> heap = new PriorityQueue<>(Comparator.comparingInt(a -> a[0]));
        heap.offer(new int[]{grid[0][0], 0, 0});
        best[0][0] = grid[0][0];
        int[][] directions = {{1, 0}, {-1, 0}, {0, 1}, {0, -1}};

        while (!heap.isEmpty()) {
            int[] state = heap.poll();
            int time = state[0], row = state[1], column = state[2];
            if (time != best[row][column]) continue;
            if (row == n - 1 && column == n - 1) return time;
            for (int[] direction : directions) {
                int nextRow = row + direction[0];
                int nextColumn = column + direction[1];
                if (nextRow < 0 || nextRow == n || nextColumn < 0 || nextColumn == n) continue;
                int candidate = Math.max(time, grid[nextRow][nextColumn]);
                if (candidate < best[nextRow][nextColumn]) {
                    best[nextRow][nextColumn] = candidate;
                    heap.offer(new int[]{candidate, nextRow, nextColumn});
                }
            }
        }
        return -1;
    }
}
```

### 97. Alien Dictionary (LC 269, Hard, Premium)

**Idea:** Create precedence edges from the first differing letters of adjacent words, then topologically sort all letters.  
**Time:** O(C + E) **Space:** O(C + E)

```java
class Solution {
    public String alienOrder(String[] words) {
        Map<Character, Set<Character>> graph = new HashMap<>();
        Map<Character, Integer> indegree = new HashMap<>();
        for (String word : words) {
            for (char letter : word.toCharArray()) {
                graph.putIfAbsent(letter, new HashSet<>());
                indegree.putIfAbsent(letter, 0);
            }
        }

        for (int i = 0; i + 1 < words.length; i++) {
            String first = words[i], second = words[i + 1];
            if (first.length() > second.length() && first.startsWith(second)) return "";
            int length = Math.min(first.length(), second.length());
            for (int j = 0; j < length; j++) {
                char from = first.charAt(j), to = second.charAt(j);
                if (from == to) continue;
                if (graph.get(from).add(to)) indegree.put(to, indegree.get(to) + 1);
                break;
            }
        }

        Queue<Character> queue = new ArrayDeque<>();
        for (Map.Entry<Character, Integer> entry : indegree.entrySet()) {
            if (entry.getValue() == 0) queue.offer(entry.getKey());
        }
        StringBuilder order = new StringBuilder();
        while (!queue.isEmpty()) {
            char letter = queue.poll();
            order.append(letter);
            for (char next : graph.get(letter)) {
                indegree.put(next, indegree.get(next) - 1);
                if (indegree.get(next) == 0) queue.offer(next);
            }
        }
        return order.length() == indegree.size() ? order.toString() : "";
    }
}
```

### 98. Cheapest Flights Within K Stops (LC 787, Medium)

**Idea:** Perform k + 1 Bellman-Ford relaxation rounds, always reading the previous round's distances.  
**Time:** O(kE) **Space:** O(V)

```java
class Solution {
    public int findCheapestPrice(int n, int[][] flights, int src, int dst, int k) {
        int infinity = Integer.MAX_VALUE / 4;
        int[] distance = new int[n];
        Arrays.fill(distance, infinity);
        distance[src] = 0;

        for (int edges = 0; edges <= k; edges++) {
            int[] next = distance.clone();
            for (int[] flight : flights) {
                int from = flight[0], to = flight[1], price = flight[2];
                if (distance[from] != infinity) {
                    next[to] = Math.min(next[to], distance[from] + price);
                }
            }
            distance = next;
        }
        return distance[dst] == infinity ? -1 : distance[dst];
    }
}
```

## 1-D Dynamic Programming

### 99. Climbing Stairs (LC 70, Easy)

**Idea:** The ways to reach a step equal the sum of the previous two step counts.  
**Time:** O(n) **Space:** O(1)

```java
class Solution {
    public int climbStairs(int n) {
        if (n <= 2) return n;
        int previous = 1, current = 2;
        for (int step = 3; step <= n; step++) {
            int next = previous + current;
            previous = current;
            current = next;
        }
        return current;
    }
}
```

### 100. Min Cost Climbing Stairs (LC 746, Easy)

**Idea:** Work backward with two rolling costs; from each step, pay its cost plus the cheaper next state.  
**Time:** O(n) **Space:** O(1)

```java
class Solution {
    public int minCostClimbingStairs(int[] cost) {
        int oneStepAhead = 0, twoStepsAhead = 0;
        for (int i = cost.length - 1; i >= 0; i--) {
            int current = cost[i] + Math.min(oneStepAhead, twoStepsAhead);
            twoStepsAhead = oneStepAhead;
            oneStepAhead = current;
        }
        return Math.min(oneStepAhead, twoStepsAhead);
    }
}
```

### 101. House Robber (LC 198, Medium)

**Idea:** At each house, choose between skipping it and adding it to the best result two houses back.  
**Time:** O(n) **Space:** O(1)

```java
class Solution {
    public int rob(int[] nums) {
        int twoBack = 0, oneBack = 0;
        for (int money : nums) {
            int current = Math.max(oneBack, twoBack + money);
            twoBack = oneBack;
            oneBack = current;
        }
        return oneBack;
    }
}
```

### 102. House Robber II (LC 213, Medium)

**Idea:** The first and last houses cannot both be chosen, so solve two ordinary linear robber ranges.  
**Time:** O(n) **Space:** O(1)

```java
class Solution {
    public int rob(int[] nums) {
        if (nums.length == 1) return nums[0];
        return Math.max(robRange(nums, 0, nums.length - 2),
                        robRange(nums, 1, nums.length - 1));
    }

    private int robRange(int[] nums, int start, int end) {
        int twoBack = 0, oneBack = 0;
        for (int i = start; i <= end; i++) {
            int current = Math.max(oneBack, twoBack + nums[i]);
            twoBack = oneBack;
            oneBack = current;
        }
        return oneBack;
    }
}
```

### 103. Longest Palindromic Substring (LC 5, Medium)

**Idea:** Expand around every odd and even center and retain the longest palindrome found.  
**Time:** O(n^2) **Space:** O(1)

```java
class Solution {
    public String longestPalindrome(String s) {
        if (s.isEmpty()) return "";
        int start = 0, end = 0;
        for (int center = 0; center < s.length(); center++) {
            int odd = expand(s, center, center);
            int even = expand(s, center, center + 1);
            int length = Math.max(odd, even);
            if (length > end - start + 1) {
                start = center - (length - 1) / 2;
                end = center + length / 2;
            }
        }
        return s.substring(start, end + 1);
    }

    private int expand(String s, int left, int right) {
        while (left >= 0 && right < s.length() && s.charAt(left) == s.charAt(right)) {
            left--;
            right++;
        }
        return right - left - 1;
    }
}
```

### 104. Palindromic Substrings (LC 647, Medium)

**Idea:** Expand around every odd and even center and count each valid palindrome encountered.  
**Time:** O(n^2) **Space:** O(1)

```java
class Solution {
    public int countSubstrings(String s) {
        int answer = 0;
        for (int center = 0; center < s.length(); center++) {
            answer += expand(s, center, center);
            answer += expand(s, center, center + 1);
        }
        return answer;
    }

    private int expand(String s, int left, int right) {
        int count = 0;
        while (left >= 0 && right < s.length()
                && s.charAt(left) == s.charAt(right)) {
            count++;
            left--;
            right++;
        }
        return count;
    }
}
```

### 105. Decode Ways (LC 91, Medium)

**Idea:** Use rolling DP: decode the final one digit when valid and the final two digits when between 10 and 26.  
**Time:** O(n) **Space:** O(1)

```java
class Solution {
    public int numDecodings(String s) {
        int twoBack = 1;
        int oneBack = s.charAt(0) == '0' ? 0 : 1;
        for (int i = 1; i < s.length(); i++) {
            int current = 0;
            if (s.charAt(i) != '0') current += oneBack;
            int pair = (s.charAt(i - 1) - '0') * 10 + s.charAt(i) - '0';
            if (pair >= 10 && pair <= 26) current += twoBack;
            twoBack = oneBack;
            oneBack = current;
        }
        return oneBack;
    }
}
```

### 106. Coin Change (LC 322, Medium)

**Idea:** Build the minimum coin count for every amount from previously solved smaller amounts.  
**Time:** O(amount * number of coins) **Space:** O(amount)

```java
class Solution {
    public int coinChange(int[] coins, int amount) {
        int[] dp = new int[amount + 1];
        Arrays.fill(dp, amount + 1);
        dp[0] = 0;
        for (int coin : coins) {
            for (int value = coin; value <= amount; value++) {
                dp[value] = Math.min(dp[value], dp[value - coin] + 1);
            }
        }
        return dp[amount] > amount ? -1 : dp[amount];
    }
}
```

### 107. Maximum Product Subarray (LC 152, Medium)

**Idea:** Track both the maximum and minimum product ending here because a negative value can swap their roles.  
**Time:** O(n) **Space:** O(1)

```java
class Solution {
    public int maxProduct(int[] nums) {
        int maximum = nums[0], minimum = nums[0], answer = nums[0];
        for (int i = 1; i < nums.length; i++) {
            int value = nums[i];
            if (value < 0) {
                int temporary = maximum;
                maximum = minimum;
                minimum = temporary;
            }
            maximum = Math.max(value, maximum * value);
            minimum = Math.min(value, minimum * value);
            answer = Math.max(answer, maximum);
        }
        return answer;
    }
}
```

### 108. Word Break (LC 139, Medium)

**Idea:** Mark each prefix reachable when an earlier reachable prefix is followed by a dictionary word.  
**Time:** O(n^2) **Space:** O(n)

```java
class Solution {
    public boolean wordBreak(String s, List<String> wordDict) {
        Set<String> words = new HashSet<>(wordDict);
        int maxLength = 0;
        for (String word : wordDict) maxLength = Math.max(maxLength, word.length());
        boolean[] dp = new boolean[s.length() + 1];
        dp[0] = true;
        for (int end = 1; end <= s.length(); end++) {
            for (int start = Math.max(0, end - maxLength); start < end; start++) {
                if (dp[start] && words.contains(s.substring(start, end))) {
                    dp[end] = true;
                    break;
                }
            }
        }
        return dp[s.length()];
    }
}
```

### 109. Longest Increasing Subsequence (LC 300, Medium)

**Idea:** Maintain the smallest possible tail for an increasing subsequence of each length.  
**Time:** O(n log n) **Space:** O(n)

```java
class Solution {
    public int lengthOfLIS(int[] nums) {
        int[] tails = new int[nums.length];
        int size = 0;
        for (int value : nums) {
            int left = 0, right = size;
            while (left < right) {
                int mid = left + (right - left) / 2;
                if (tails[mid] < value) left = mid + 1;
                else right = mid;
            }
            tails[left] = value;
            if (left == size) size++;
        }
        return size;
    }
}
```

### 110. Partition Equal Subset Sum (LC 416, Medium)

**Idea:** Reduce to a 0/1 subset-sum target of half the total and update reachable sums backward.  
**Time:** O(nS) **Space:** O(S)

```java
class Solution {
    public boolean canPartition(int[] nums) {
        int sum = 0;
        for (int value : nums) sum += value;
        if ((sum & 1) == 1) return false;
        int target = sum / 2;
        boolean[] reachable = new boolean[target + 1];
        reachable[0] = true;
        for (int value : nums) {
            for (int current = target; current >= value; current--) {
                reachable[current] |= reachable[current - value];
            }
        }
        return reachable[target];
    }
}
```

## 2-D Dynamic Programming

### 111. Unique Paths (LC 62, Medium)

**Idea:** Use one DP row where each cell accumulates paths from above and from the left.  
**Time:** O(mn) **Space:** O(n)

```java
class Solution {
    public int uniquePaths(int m, int n) {
        int[] paths = new int[n];
        Arrays.fill(paths, 1);
        for (int row = 1; row < m; row++) {
            for (int column = 1; column < n; column++) {
                paths[column] += paths[column - 1];
            }
        }
        return paths[n - 1];
    }
}
```

### 112. Longest Common Subsequence (LC 1143, Medium)

**Idea:** Build the LCS of prefixes: equal characters extend the diagonal; otherwise take the better adjacent prefix.  
**Time:** O(mn) **Space:** O(n)

```java
class Solution {
    public int longestCommonSubsequence(String text1, String text2) {
        if (text2.length() > text1.length()) {
            String temporary = text1;
            text1 = text2;
            text2 = temporary;
        }
        int[] previous = new int[text2.length() + 1];
        for (int i = 1; i <= text1.length(); i++) {
            int diagonal = 0;
            for (int j = 1; j <= text2.length(); j++) {
                int above = previous[j];
                if (text1.charAt(i - 1) == text2.charAt(j - 1)) {
                    previous[j] = diagonal + 1;
                } else {
                    previous[j] = Math.max(previous[j], previous[j - 1]);
                }
                diagonal = above;
            }
        }
        return previous[text2.length()];
    }
}
```

### 113. Best Time to Buy and Sell Stock with Cooldown (LC 309, Medium)

**Idea:** Track the best hold, just-sold, and resting states; buying is allowed only from the resting state.  
**Time:** O(n) **Space:** O(1)

```java
class Solution {
    public int maxProfit(int[] prices) {
        int hold = -prices[0];
        int sold = Integer.MIN_VALUE / 2;
        int rest = 0;
        for (int i = 1; i < prices.length; i++) {
            int previousHold = hold;
            int previousSold = sold;
            int previousRest = rest;
            hold = Math.max(previousHold, previousRest - prices[i]);
            sold = previousHold + prices[i];
            rest = Math.max(previousRest, previousSold);
        }
        return Math.max(sold, rest);
    }
}
```

### 114. Coin Change II (LC 518, Medium)

**Idea:** Process coin types outside the loop so each amount counts combinations rather than orderings.  
**Time:** O(amount * n) **Space:** O(amount)

```java
class Solution {
    public int change(int amount, int[] coins) {
        int[] ways = new int[amount + 1];
        ways[0] = 1;
        for (int coin : coins) {
            for (int value = coin; value <= amount; value++) {
                ways[value] += ways[value - coin];
            }
        }
        return ways[amount];
    }
}
```

### 115. Target Sum (LC 494, Medium)

**Idea:** Transform positive/negative assignments into choosing a subset whose sum is (total + target) / 2.  
**Time:** O(nS) **Space:** O(S)

```java
class Solution {
    public int findTargetSumWays(int[] nums, int target) {
        int total = 0;
        for (int value : nums) total += value;
        if (Math.abs(target) > total || ((total + target) & 1) != 0) return 0;
        int subset = (total + target) / 2;
        int[] ways = new int[subset + 1];
        ways[0] = 1;
        for (int value : nums) {
            for (int sum = subset; sum >= value; sum--) {
                ways[sum] += ways[sum - value];
            }
        }
        return ways[subset];
    }
}
```

### 116. Interleaving String (LC 97, Medium)

**Idea:** Let `dp[j]` indicate whether prefixes of the first two strings form the matching prefix of the third.  
**Time:** O(mn) **Space:** O(n)

```java
class Solution {
    public boolean isInterleave(String s1, String s2, String s3) {
        if (s1.length() + s2.length() != s3.length()) return false;
        int n = s2.length();
        boolean[] dp = new boolean[n + 1];
        dp[0] = true;
        for (int j = 1; j <= n; j++) {
            dp[j] = dp[j - 1] && s2.charAt(j - 1) == s3.charAt(j - 1);
        }
        for (int i = 1; i <= s1.length(); i++) {
            dp[0] = dp[0] && s1.charAt(i - 1) == s3.charAt(i - 1);
            for (int j = 1; j <= n; j++) {
                char target = s3.charAt(i + j - 1);
                dp[j] = (dp[j] && s1.charAt(i - 1) == target)
                        || (dp[j - 1] && s2.charAt(j - 1) == target);
            }
        }
        return dp[n];
    }
}
```

### 117. Longest Increasing Path in a Matrix (LC 329, Hard)

**Idea:** Memoize the longest increasing path beginning at each cell and explore only strictly larger neighbors.  
**Time:** O(mn) **Space:** O(mn)

```java
class Solution {
    private static final int[][] DIRECTIONS = {{1, 0}, {-1, 0}, {0, 1}, {0, -1}};

    public int longestIncreasingPath(int[][] matrix) {
        int[][] memo = new int[matrix.length][matrix[0].length];
        int answer = 0;
        for (int row = 0; row < matrix.length; row++) {
            for (int column = 0; column < matrix[0].length; column++) {
                answer = Math.max(answer, length(matrix, memo, row, column));
            }
        }
        return answer;
    }

    private int length(int[][] matrix, int[][] memo, int row, int column) {
        if (memo[row][column] != 0) return memo[row][column];
        int best = 1;
        for (int[] direction : DIRECTIONS) {
            int nextRow = row + direction[0];
            int nextColumn = column + direction[1];
            if (nextRow < 0 || nextRow == matrix.length || nextColumn < 0
                    || nextColumn == matrix[0].length
                    || matrix[nextRow][nextColumn] <= matrix[row][column]) continue;
            best = Math.max(best, 1 + length(matrix, memo, nextRow, nextColumn));
        }
        return memo[row][column] = best;
    }
}
```

### 118. Distinct Subsequences (LC 115, Hard)

**Idea:** Update subsequence counts from right to left so each source character contributes once to matching target prefixes.  
**Time:** O(mn) **Space:** O(n)

```java
class Solution {
    public int numDistinct(String s, String t) {
        long[] ways = new long[t.length() + 1];
        ways[0] = 1;
        for (char source : s.toCharArray()) {
            for (int j = t.length(); j >= 1; j--) {
                if (source == t.charAt(j - 1)) ways[j] += ways[j - 1];
            }
        }
        return (int) ways[t.length()];
    }
}
```

### 119. Edit Distance (LC 72, Medium)

**Idea:** Use prefix DP with insert, delete, and replace transitions while retaining only one row.  
**Time:** O(mn) **Space:** O(n)

```java
class Solution {
    public int minDistance(String word1, String word2) {
        int n = word2.length();
        int[] dp = new int[n + 1];
        for (int j = 0; j <= n; j++) dp[j] = j;
        for (int i = 1; i <= word1.length(); i++) {
            int diagonal = dp[0];
            dp[0] = i;
            for (int j = 1; j <= n; j++) {
                int above = dp[j];
                if (word1.charAt(i - 1) == word2.charAt(j - 1)) {
                    dp[j] = diagonal;
                } else {
                    dp[j] = 1 + Math.min(diagonal, Math.min(above, dp[j - 1]));
                }
                diagonal = above;
            }
        }
        return dp[n];
    }
}
```

### 120. Burst Balloons (LC 312, Hard)

**Idea:** Choose the last balloon burst inside every interval; its neighbors are then fixed interval boundaries.  
**Time:** O(n^3) **Space:** O(n^2)

```java
class Solution {
    public int maxCoins(int[] nums) {
        int n = nums.length;
        int[] balloons = new int[n + 2];
        balloons[0] = balloons[n + 1] = 1;
        System.arraycopy(nums, 0, balloons, 1, n);
        int[][] dp = new int[n + 2][n + 2];

        for (int length = 1; length <= n; length++) {
            for (int left = 1; left + length - 1 <= n; left++) {
                int right = left + length - 1;
                for (int last = left; last <= right; last++) {
                    dp[left][right] = Math.max(dp[left][right],
                        dp[left][last - 1] + dp[last + 1][right]
                        + balloons[left - 1] * balloons[last] * balloons[right + 1]);
                }
            }
        }
        return dp[1][n];
    }
}
```

### 121. Regular Expression Matching (LC 10, Hard)

**Idea:** Use prefix DP; '*' either removes its preceding token or consumes one matching source character.  
**Time:** O(mn) **Space:** O(mn)

```java
class Solution {
    public boolean isMatch(String s, String p) {
        int m = s.length(), n = p.length();
        boolean[][] dp = new boolean[m + 1][n + 1];
        dp[0][0] = true;
        for (int j = 2; j <= n; j++) {
            if (p.charAt(j - 1) == '*') dp[0][j] = dp[0][j - 2];
        }

        for (int i = 1; i <= m; i++) {
            for (int j = 1; j <= n; j++) {
                char pattern = p.charAt(j - 1);
                if (pattern == '.' || pattern == s.charAt(i - 1)) {
                    dp[i][j] = dp[i - 1][j - 1];
                } else if (pattern == '*') {
                    dp[i][j] = dp[i][j - 2];
                    char repeated = p.charAt(j - 2);
                    if (repeated == '.' || repeated == s.charAt(i - 1)) {
                        dp[i][j] |= dp[i - 1][j];
                    }
                }
            }
        }
        return dp[m][n];
    }
}
```

## Greedy

### 122. Maximum Subarray (LC 53, Medium)

**Idea:** At each value, either extend the current subarray or start a new one there.  
**Time:** O(n) **Space:** O(1)

```java
class Solution {
    public int maxSubArray(int[] nums) {
        int current = nums[0], best = nums[0];
        for (int i = 1; i < nums.length; i++) {
            current = Math.max(nums[i], current + nums[i]);
            best = Math.max(best, current);
        }
        return best;
    }
}
```

### 123. Jump Game (LC 55, Medium)

**Idea:** Greedily maintain the farthest index reachable so far.  
**Time:** O(n) **Space:** O(1)

```java
class Solution {
    public boolean canJump(int[] nums) {
        int farthest = 0;
        for (int i = 0; i < nums.length && i <= farthest; i++) {
            farthest = Math.max(farthest, i + nums[i]);
        }
        return farthest >= nums.length - 1;
    }
}
```

### 124. Jump Game II (LC 45, Medium)

**Idea:** Treat the current reachable range as one BFS level and extend the next range greedily.  
**Time:** O(n) **Space:** O(1)

```java
class Solution {
    public int jump(int[] nums) {
        int jumps = 0, currentEnd = 0, farthest = 0;
        for (int i = 0; i < nums.length - 1; i++) {
            farthest = Math.max(farthest, i + nums[i]);
            if (i == currentEnd) {
                jumps++;
                currentEnd = farthest;
            }
        }
        return jumps;
    }
}
```

### 125. Gas Station (LC 134, Medium)

**Idea:** A negative running tank invalidates every start since the previous reset; total gas decides feasibility.  
**Time:** O(n) **Space:** O(1)

```java
class Solution {
    public int canCompleteCircuit(int[] gas, int[] cost) {
        int total = 0, tank = 0, start = 0;
        for (int i = 0; i < gas.length; i++) {
            int gain = gas[i] - cost[i];
            total += gain;
            tank += gain;
            if (tank < 0) {
                start = i + 1;
                tank = 0;
            }
        }
        return total >= 0 ? start : -1;
    }
}
```

### 126. Hand of Straights (LC 846, Medium)

**Idea:** Always start a group at the smallest remaining card and consume one of each consecutive value.  
**Time:** O(n log n) **Space:** O(n)

```java
class Solution {
    public boolean isNStraightHand(int[] hand, int groupSize) {
        if (hand.length % groupSize != 0) return false;
        TreeMap<Integer, Integer> count = new TreeMap<>();
        for (int card : hand) count.put(card, count.getOrDefault(card, 0) + 1);

        while (!count.isEmpty()) {
            int start = count.firstKey();
            for (int card = start; card < start + groupSize; card++) {
                Integer frequency = count.get(card);
                if (frequency == null) return false;
                if (frequency == 1) count.remove(card);
                else count.put(card, frequency - 1);
            }
        }
        return true;
    }
}
```

### 127. Merge Triplets to Form Target Triplet (LC 1899, Medium)

**Idea:** Ignore triplets that exceed the target, and record which target coordinates can be supplied by valid triplets.  
**Time:** O(n) **Space:** O(1)

```java
class Solution {
    public boolean mergeTriplets(int[][] triplets, int[] target) {
        boolean first = false, second = false, third = false;
        for (int[] triplet : triplets) {
            if (triplet[0] > target[0] || triplet[1] > target[1]
                    || triplet[2] > target[2]) continue;
            if (triplet[0] == target[0]) first = true;
            if (triplet[1] == target[1]) second = true;
            if (triplet[2] == target[2]) third = true;
        }
        return first && second && third;
    }
}
```

### 128. Partition Labels (LC 763, Medium)

**Idea:** Record each character's last position and close a partition when the scan reaches the farthest last position seen.  
**Time:** O(n) **Space:** O(1)

```java
class Solution {
    public List<Integer> partitionLabels(String s) {
        int[] last = new int[26];
        for (int i = 0; i < s.length(); i++) last[s.charAt(i) - 'a'] = i;

        List<Integer> answer = new ArrayList<>();
        int start = 0, end = 0;
        for (int i = 0; i < s.length(); i++) {
            end = Math.max(end, last[s.charAt(i) - 'a']);
            if (i == end) {
                answer.add(end - start + 1);
                start = i + 1;
            }
        }
        return answer;
    }
}
```

### 129. Valid Parenthesis String (LC 678, Medium)

**Idea:** Track the minimum and maximum possible unmatched open counts after interpreting each '*' flexibly.  
**Time:** O(n) **Space:** O(1)

```java
class Solution {
    public boolean checkValidString(String s) {
        int minimumOpen = 0, maximumOpen = 0;
        for (char c : s.toCharArray()) {
            if (c == '(') {
                minimumOpen++;
                maximumOpen++;
            } else if (c == ')') {
                minimumOpen = Math.max(0, minimumOpen - 1);
                maximumOpen--;
            } else {
                minimumOpen = Math.max(0, minimumOpen - 1);
                maximumOpen++;
            }
            if (maximumOpen < 0) return false;
        }
        return minimumOpen == 0;
    }
}
```

## Intervals

### 130. Insert Interval (LC 57, Medium)

**Idea:** Copy intervals before the new range, merge every overlap, then append the remaining intervals.  
**Time:** O(n) **Space:** O(n) for the output

```java
class Solution {
    public int[][] insert(int[][] intervals, int[] newInterval) {
        List<int[]> ans = new ArrayList<>();
        int i = 0;
        while (i < intervals.length && intervals[i][1] < newInterval[0]) {
            ans.add(intervals[i++]);
        }
        while (i < intervals.length && intervals[i][0] <= newInterval[1]) {
            newInterval[0] = Math.min(newInterval[0], intervals[i][0]);
            newInterval[1] = Math.max(newInterval[1], intervals[i][1]);
            i++;
        }
        ans.add(newInterval);
        while (i < intervals.length) ans.add(intervals[i++]);
        return ans.toArray(new int[ans.size()][]);
    }
}
```

### 131. Merge Intervals (LC 56, Medium)

**Idea:** Sort by start, then merge into the last output interval whenever ranges overlap.  
**Time:** O(n log n) **Space:** O(log n) to O(n), depending on the sort

```java
class Solution {
    public int[][] merge(int[][] intervals) {
        Arrays.sort(intervals, Comparator.comparingInt(a -> a[0]));
        List<int[]> merged = new ArrayList<>();
        for (int[] interval : intervals) {
            if (merged.isEmpty() || merged.get(merged.size() - 1)[1] < interval[0]) {
                merged.add(interval.clone());
            } else {
                int[] last = merged.get(merged.size() - 1);
                last[1] = Math.max(last[1], interval[1]);
            }
        }
        return merged.toArray(new int[merged.size()][]);
    }
}
```

### 132. Non-overlapping Intervals (LC 435, Medium)

**Idea:** Sort by end time and greedily retain intervals that finish earliest; every overlap is removed.  
**Time:** O(n log n) **Space:** O(log n) to O(n) for sorting

```java
class Solution {
    public int eraseOverlapIntervals(int[][] intervals) {
        Arrays.sort(intervals, Comparator.comparingInt(interval -> interval[1]));
        int removals = 0;
        int previousEnd = Integer.MIN_VALUE;
        for (int[] interval : intervals) {
            if (interval[0] >= previousEnd) previousEnd = interval[1];
            else removals++;
        }
        return removals;
    }
}
```

### 133. Meeting Rooms (LC 252, Easy, Premium)

**Idea:** Sort meetings by start time and ensure every meeting starts no earlier than the previous meeting ends.  
**Time:** O(n log n) **Space:** O(log n) to O(n) for sorting

```java
class Solution {
    public boolean canAttendMeetings(int[][] intervals) {
        Arrays.sort(intervals, Comparator.comparingInt(interval -> interval[0]));
        for (int i = 1; i < intervals.length; i++) {
            if (intervals[i][0] < intervals[i - 1][1]) return false;
        }
        return true;
    }
}
```

### 134. Meeting Rooms II (LC 253, Medium, Premium)

**Idea:** Sort starts and ends separately; advance the end pointer when a room frees, otherwise allocate another room.  
**Time:** O(n log n) **Space:** O(n)

```java
class Solution {
    public int minMeetingRooms(int[][] intervals) {
        int n = intervals.length;
        int[] starts = new int[n];
        int[] ends = new int[n];
        for (int i = 0; i < n; i++) {
            starts[i] = intervals[i][0];
            ends[i] = intervals[i][1];
        }
        Arrays.sort(starts);
        Arrays.sort(ends);

        int rooms = 0, endIndex = 0;
        for (int start : starts) {
            if (start >= ends[endIndex]) endIndex++;
            else rooms++;
        }
        return rooms;
    }
}
```

### 135. Minimum Interval to Include Each Query (LC 1851, Hard)

**Idea:** Sort intervals and queries; add eligible intervals to a size-ordered heap and remove those ending too early.  
**Time:** O((n + q) log n) **Space:** O(n + q)

```java
class Solution {
    public int[] minInterval(int[][] intervals, int[] queries) {
        Arrays.sort(intervals, Comparator.comparingInt(interval -> interval[0]));
        int[][] orderedQueries = new int[queries.length][2];
        for (int i = 0; i < queries.length; i++) {
            orderedQueries[i] = new int[]{queries[i], i};
        }
        Arrays.sort(orderedQueries, Comparator.comparingInt(query -> query[0]));

        PriorityQueue<int[]> heap = new PriorityQueue<>((a, b) -> {
            if (a[0] != b[0]) return Integer.compare(a[0], b[0]);
            return Integer.compare(a[1], b[1]);
        });
        int[] answer = new int[queries.length];
        Arrays.fill(answer, -1);
        int intervalIndex = 0;

        for (int[] query : orderedQueries) {
            int value = query[0];
            while (intervalIndex < intervals.length && intervals[intervalIndex][0] <= value) {
                int[] interval = intervals[intervalIndex++];
                heap.offer(new int[]{interval[1] - interval[0] + 1, interval[1]});
            }
            while (!heap.isEmpty() && heap.peek()[1] < value) heap.poll();
            if (!heap.isEmpty()) answer[query[1]] = heap.peek()[0];
        }
        return answer;
    }
}
```

## Math & Geometry

### 136. Rotate Image (LC 48, Medium)

**Idea:** Transpose the matrix across its main diagonal, then reverse every row.  
**Time:** O(n^2) **Space:** O(1)

```java
class Solution {
    public void rotate(int[][] matrix) {
        int n = matrix.length;
        for (int r = 0; r < n; r++) {
            for (int c = r + 1; c < n; c++) {
                int tmp = matrix[r][c];
                matrix[r][c] = matrix[c][r];
                matrix[c][r] = tmp;
            }
        }
        for (int[] row : matrix) {
            for (int l = 0, r = n - 1; l < r; l++, r--) {
                int tmp = row[l];
                row[l] = row[r];
                row[r] = tmp;
            }
        }
    }
}
```

### 137. Spiral Matrix (LC 54, Medium)

**Idea:** Repeatedly consume the top row, right column, bottom row, and left column.  
**Time:** O(mn) **Space:** O(1) extra, excluding output

```java
class Solution {
    public List<Integer> spiralOrder(int[][] matrix) {
        List<Integer> ans = new ArrayList<>();
        int top = 0, bottom = matrix.length - 1;
        int left = 0, right = matrix[0].length - 1;
        while (top <= bottom && left <= right) {
            for (int c = left; c <= right; c++) ans.add(matrix[top][c]);
            top++;
            for (int r = top; r <= bottom; r++) ans.add(matrix[r][right]);
            right--;
            if (top <= bottom) {
                for (int c = right; c >= left; c--) ans.add(matrix[bottom][c]);
                bottom--;
            }
            if (left <= right) {
                for (int r = bottom; r >= top; r--) ans.add(matrix[r][left]);
                left++;
            }
        }
        return ans;
    }
}
```

### 138. Set Matrix Zeroes (LC 73, Medium)

**Idea:** Use the first row and first column as marker storage, with two flags for their original state.  
**Time:** O(mn) **Space:** O(1)

```java
class Solution {
    public void setZeroes(int[][] matrix) {
        int m = matrix.length, n = matrix[0].length;
        boolean firstRow = false, firstCol = false;
        for (int c = 0; c < n; c++) firstRow |= matrix[0][c] == 0;
        for (int r = 0; r < m; r++) firstCol |= matrix[r][0] == 0;

        for (int r = 1; r < m; r++) {
            for (int c = 1; c < n; c++) {
                if (matrix[r][c] == 0) {
                    matrix[r][0] = 0;
                    matrix[0][c] = 0;
                }
            }
        }
        for (int r = 1; r < m; r++) {
            for (int c = 1; c < n; c++) {
                if (matrix[r][0] == 0 || matrix[0][c] == 0) matrix[r][c] = 0;
            }
        }
        if (firstRow) Arrays.fill(matrix[0], 0);
        if (firstCol) for (int r = 0; r < m; r++) matrix[r][0] = 0;
    }
}
```

### 139. Happy Number (LC 202, Easy)

**Idea:** Apply Floyd cycle detection to the repeated sum-of-squared-digits transformation.  
**Time:** O(log n) **Space:** O(1)

```java
class Solution {
    public boolean isHappy(int n) {
        int slow = n, fast = next(n);
        while (slow != fast) {
            slow = next(slow);
            fast = next(next(fast));
        }
        return slow == 1;
    }

    private int next(int n) {
        int sum = 0;
        while (n > 0) {
            int digit = n % 10;
            sum += digit * digit;
            n /= 10;
        }
        return sum;
    }
}
```

### 140. Plus One (LC 66, Easy)

**Idea:** Propagate a carry from the final digit; allocate a longer array only when every digit is nine.  
**Time:** O(n) **Space:** O(1) extra, excluding a possible output array

```java
class Solution {
    public int[] plusOne(int[] digits) {
        for (int i = digits.length - 1; i >= 0; i--) {
            if (digits[i] < 9) {
                digits[i]++;
                return digits;
            }
            digits[i] = 0;
        }
        int[] result = new int[digits.length + 1];
        result[0] = 1;
        return result;
    }
}
```

### 141. Pow(x, n) (LC 50, Medium)

**Idea:** Use exponentiation by squaring and store the exponent in a `long` for `Integer.MIN_VALUE`.  
**Time:** O(log |n|) **Space:** O(1)

```java
class Solution {
    public double myPow(double x, int n) {
        long exponent = n;
        if (exponent < 0) {
            x = 1.0 / x;
            exponent = -exponent;
        }
        double result = 1.0;
        while (exponent > 0) {
            if ((exponent & 1) == 1) result *= x;
            x *= x;
            exponent >>= 1;
        }
        return result;
    }
}
```

### 142. Multiply Strings (LC 43, Medium)

**Idea:** Accumulate every digit product into its two decimal positions, then normalize carries and skip leading zeroes.  
**Time:** O(mn) **Space:** O(m + n)

```java
class Solution {
    public String multiply(String num1, String num2) {
        if (num1.equals("0") || num2.equals("0")) return "0";
        int[] digits = new int[num1.length() + num2.length()];
        for (int i = num1.length() - 1; i >= 0; i--) {
            for (int j = num2.length() - 1; j >= 0; j--) {
                int product = (num1.charAt(i) - '0') * (num2.charAt(j) - '0');
                int low = i + j + 1;
                int sum = product + digits[low];
                digits[low] = sum % 10;
                digits[low - 1] += sum / 10;
            }
        }

        StringBuilder answer = new StringBuilder();
        int index = digits[0] == 0 ? 1 : 0;
        while (index < digits.length) answer.append(digits[index++]);
        return answer.toString();
    }
}
```

### 143. Detect Squares (LC 2013, Medium)

**Idea:** Group point counts by y-coordinate; for each horizontal partner of the query, test squares above and below.  
**Time:** add: O(1), count: O(p) **Space:** O(n)

```java
class DetectSquares {
    private final Map<Integer, Map<Integer, Integer>> rows = new HashMap<>();

    public void add(int[] point) {
        rows.computeIfAbsent(point[1], unused -> new HashMap<>())
            .put(point[0], rows.get(point[1]).getOrDefault(point[0], 0) + 1);
    }

    public int count(int[] point) {
        int x = point[0], y = point[1], answer = 0;
        Map<Integer, Integer> row = rows.get(y);
        if (row == null) return 0;
        for (Map.Entry<Integer, Integer> partner : row.entrySet()) {
            int otherX = partner.getKey();
            if (otherX == x) continue;
            int side = otherX - x;
            answer += partner.getValue() * occurrences(y + side, x)
                    * occurrences(y + side, otherX);
            answer += partner.getValue() * occurrences(y - side, x)
                    * occurrences(y - side, otherX);
        }
        return answer;
    }

    private int occurrences(int y, int x) {
        Map<Integer, Integer> row = rows.get(y);
        return row == null ? 0 : row.getOrDefault(x, 0);
    }
}
```

## Bit Manipulation

### 144. Single Number (LC 136, Easy)

**Idea:** XOR cancels every paired value and leaves the unpaired value.  
**Time:** O(n) **Space:** O(1)

```java
class Solution {
    public int singleNumber(int[] nums) {
        int result = 0;
        for (int value : nums) result ^= value;
        return result;
    }
}
```

### 145. Number of 1 Bits (LC 191, Easy)

**Idea:** Repeatedly clear the lowest set bit with `n & (n - 1)`.  
**Time:** O(1) **Space:** O(1)

```java
class Solution {
    public int hammingWeight(int n) {
        int count = 0;
        while (n != 0) {
            n &= n - 1;
            count++;
        }
        return count;
    }
}
```

### 146. Counting Bits (LC 338, Easy)

**Idea:** Reuse the answer for i shifted right, then add i's least-significant bit.  
**Time:** O(n) **Space:** O(n)

```java
class Solution {
    public int[] countBits(int n) {
        int[] bits = new int[n + 1];
        for (int value = 1; value <= n; value++) {
            bits[value] = bits[value >> 1] + (value & 1);
        }
        return bits;
    }
}
```

### 147. Reverse Bits (LC 190, Easy)

**Idea:** Shift one input bit at a time into the result in reverse order.  
**Time:** O(1) **Space:** O(1)

```java
class Solution {
    public int reverseBits(int n) {
        int result = 0;
        for (int i = 0; i < 32; i++) {
            result = (result << 1) | (n & 1);
            n >>>= 1;
        }
        return result;
    }
}
```

### 148. Missing Number (LC 268, Easy)

**Idea:** XOR every index and value; paired numbers cancel and leave the missing value.  
**Time:** O(n) **Space:** O(1)

```java
class Solution {
    public int missingNumber(int[] nums) {
        int missing = nums.length;
        for (int i = 0; i < nums.length; i++) missing ^= i ^ nums[i];
        return missing;
    }
}
```

### 149. Sum of Two Integers (LC 371, Medium)

**Idea:** XOR adds without carries; shifted AND computes carries. Repeat until no carry remains.  
**Time:** O(1) **Space:** O(1)

```java
class Solution {
    public int getSum(int a, int b) {
        while (b != 0) {
            int carry = (a & b) << 1;
            a ^= b;
            b = carry;
        }
        return a;
    }
}
```

### 150. Reverse Integer (LC 7, Medium)

**Idea:** Pop decimal digits into the reversed value while checking bounds before each multiply-and-add.  
**Time:** O(log |x|) **Space:** O(1)

```java
class Solution {
    public int reverse(int x) {
        int reversed = 0;
        while (x != 0) {
            int digit = x % 10;
            x /= 10;
            if (reversed > Integer.MAX_VALUE / 10
                    || (reversed == Integer.MAX_VALUE / 10 && digit > 7)) return 0;
            if (reversed < Integer.MIN_VALUE / 10
                    || (reversed == Integer.MIN_VALUE / 10 && digit < -8)) return 0;
            reversed = reversed * 10 + digit;
        }
        return reversed;
    }
}
```
