# LeetCode Top Interview 150 - Java Solutions

This document covers the LeetCode Top Interview 150 study plan and provides concise Java solutions for each problem.

**Notes:** `java.util.*`, `ListNode`, `TreeNode`, and the problem-specific `Node` classes are assumed to be provided by LeetCode. For brevity, helper comments are minimal and code is written in standard LeetCode style. Each solution is original, concise, and interview-oriented.

## Contents

Problem numbers follow the study-plan order.

| Problems | Topic | Problems | Topic |
|---:|---|---:|---|
| 1-24 | Array / String | 89-94 | Graph General |
| 25-29 | Two Pointers | 95-97 | Graph BFS |
| 30-33 | Sliding Window | 98-100 | Trie |
| 34-38 | Matrix | 101-107 | Backtracking |
| 39-47 | Hashmap | 108-111 | Divide & Conquer |
| 48-51 | Intervals | 112-113 | Kadane's Algorithm |
| 52-56 | Stack | 114-120 | Binary Search |
| 57-67 | Linked List | 121-124 | Heap |
| 68-81 | Binary Tree General | 125-130 | Bit Manipulation |
| 82-85 | Binary Tree BFS | 131-136 | Math |
| 86-88 | Binary Search Tree | 137-141 | 1D Dynamic Programming |
|  |  | 142-150 | Multidimensional Dynamic Programming |

## Array / String

### 1. Merge Sorted Array (LC 88)

**Idea:** Merge from the back so unread values in `nums1` are never overwritten.  
**Time:** O(m + n) **Space:** O(1)

```java
class Solution {
    public void merge(int[] nums1, int m, int[] nums2, int n) {
        int i = m - 1, j = n - 1, write = m + n - 1;
        while (j >= 0) {
            if (i >= 0 && nums1[i] > nums2[j]) nums1[write--] = nums1[i--];
            else nums1[write--] = nums2[j--];
        }
    }
}
```

### 2. Remove Element (LC 27)

**Idea:** Compact every value different from `val` into the front of the array.  
**Time:** O(n) **Space:** O(1)

```java
class Solution {
    public int removeElement(int[] nums, int val) {
        int write = 0;
        for (int x : nums) {
            if (x != val) nums[write++] = x;
        }
        return write;
    }
}
```

### 3. Remove Duplicates from Sorted Array (LC 26)

**Idea:** Keep one write position and copy a value only when it differs from the last kept value.  
**Time:** O(n) **Space:** O(1)

```java
class Solution {
    public int removeDuplicates(int[] nums) {
        if (nums.length == 0) return 0;
        int write = 1;
        for (int read = 1; read < nums.length; read++) {
            if (nums[read] != nums[write - 1]) nums[write++] = nums[read];
        }
        return write;
    }
}
```

### 4. Remove Duplicates from Sorted Array II (LC 80)

**Idea:** A value may be written when fewer than two values are kept or it differs from the value two positions back.  
**Time:** O(n) **Space:** O(1)

```java
class Solution {
    public int removeDuplicates(int[] nums) {
        int write = 0;
        for (int x : nums) {
            if (write < 2 || x != nums[write - 2]) nums[write++] = x;
        }
        return write;
    }
}
```

### 5. Majority Element (LC 169)

**Idea:** Boyer-Moore voting cancels different values; the surviving candidate is the majority.  
**Time:** O(n) **Space:** O(1)

```java
class Solution {
    public int majorityElement(int[] nums) {
        int candidate = 0, count = 0;
        for (int x : nums) {
            if (count == 0) candidate = x;
            count += x == candidate ? 1 : -1;
        }
        return candidate;
    }
}
```

### 6. Rotate Array (LC 189)

**Idea:** Reverse the whole array, then reverse the first `k` values and the remaining values.  
**Time:** O(n) **Space:** O(1)

```java
class Solution {
    public void rotate(int[] nums, int k) {
        k %= nums.length;
        reverse(nums, 0, nums.length - 1);
        reverse(nums, 0, k - 1);
        reverse(nums, k, nums.length - 1);
    }

    private void reverse(int[] a, int l, int r) {
        while (l < r) {
            int tmp = a[l];
            a[l++] = a[r];
            a[r--] = tmp;
        }
    }
}
```

### 7. Best Time to Buy and Sell Stock (LC 121)

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

### 8. Best Time to Buy and Sell Stock II (LC 122)

**Idea:** Collect every positive day-to-day price increase.  
**Time:** O(n) **Space:** O(1)

```java
class Solution {
    public int maxProfit(int[] prices) {
        int profit = 0;
        for (int i = 1; i < prices.length; i++) {
            if (prices[i] > prices[i - 1]) profit += prices[i] - prices[i - 1];
        }
        return profit;
    }
}
```

### 9. Jump Game (LC 55)

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

### 10. Jump Game II (LC 45)

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

### 11. H-Index (LC 274)

**Idea:** Bucket citation counts at `n`, then scan downward until at least `h` papers have `h` citations.  
**Time:** O(n) **Space:** O(n)

```java
class Solution {
    public int hIndex(int[] citations) {
        int n = citations.length;
        int[] count = new int[n + 1];
        for (int c : citations) count[Math.min(c, n)]++;
        int papers = 0;
        for (int h = n; h >= 0; h--) {
            papers += count[h];
            if (papers >= h) return h;
        }
        return 0;
    }
}
```

### 12. Insert Delete GetRandom O(1) (LC 380)

**Idea:** Store values in an array list and map each value to its index; removal swaps with the last value.  
**Time:** O(1) average per operation **Space:** O(n)

```java
class RandomizedSet {
    private final List<Integer> values = new ArrayList<>();
    private final Map<Integer, Integer> index = new HashMap<>();
    private final Random random = new Random();

    public RandomizedSet() {}

    public boolean insert(int val) {
        if (index.containsKey(val)) return false;
        index.put(val, values.size());
        values.add(val);
        return true;
    }

    public boolean remove(int val) {
        Integer i = index.get(val);
        if (i == null) return false;
        int last = values.get(values.size() - 1);
        values.set(i, last);
        index.put(last, i);
        values.remove(values.size() - 1);
        index.remove(val);
        return true;
    }

    public int getRandom() {
        return values.get(random.nextInt(values.size()));
    }
}
```

### 13. Product of Array Except Self (LC 238)

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

### 14. Gas Station (LC 134)

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

### 15. Candy (LC 135)

**Idea:** One pass enforces the left-neighbor rule; a reverse pass enforces the right-neighbor rule.  
**Time:** O(n) **Space:** O(n)

```java
class Solution {
    public int candy(int[] ratings) {
        int n = ratings.length;
        int[] candies = new int[n];
        Arrays.fill(candies, 1);
        for (int i = 1; i < n; i++) {
            if (ratings[i] > ratings[i - 1]) candies[i] = candies[i - 1] + 1;
        }
        for (int i = n - 2; i >= 0; i--) {
            if (ratings[i] > ratings[i + 1]) {
                candies[i] = Math.max(candies[i], candies[i + 1] + 1);
            }
        }
        int total = 0;
        for (int c : candies) total += c;
        return total;
    }
}
```

### 16. Trapping Rain Water (LC 42)

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

### 17. Roman to Integer (LC 13)

**Idea:** Scan from right to left; subtract a numeral when it is smaller than the largest numeral already seen.  
**Time:** O(n) **Space:** O(1)

```java
class Solution {
    public int romanToInt(String s) {
        int total = 0, previous = 0;
        for (int i = s.length() - 1; i >= 0; i--) {
            int value = value(s.charAt(i));
            total += value < previous ? -value : value;
            previous = Math.max(previous, value);
        }
        return total;
    }

    private int value(char c) {
        switch (c) {
            case 'I': return 1;
            case 'V': return 5;
            case 'X': return 10;
            case 'L': return 50;
            case 'C': return 100;
            case 'D': return 500;
            default: return 1000;
        }
    }
}
```

### 18. Integer to Roman (LC 12)

**Idea:** Greedily append the largest Roman token that fits the remaining value.  
**Time:** O(1) **Space:** O(1)

```java
class Solution {
    public String intToRoman(int num) {
        int[] values = {1000, 900, 500, 400, 100, 90, 50, 40, 10, 9, 5, 4, 1};
        String[] symbols = {"M", "CM", "D", "CD", "C", "XC", "L", "XL", "X", "IX", "V", "IV", "I"};
        StringBuilder ans = new StringBuilder();
        for (int i = 0; i < values.length; i++) {
            while (num >= values[i]) {
                num -= values[i];
                ans.append(symbols[i]);
            }
        }
        return ans.toString();
    }
}
```

### 19. Length of Last Word (LC 58)

**Idea:** Skip trailing spaces, then count characters until the next space.  
**Time:** O(n) **Space:** O(1)

```java
class Solution {
    public int lengthOfLastWord(String s) {
        int i = s.length() - 1;
        while (i >= 0 && s.charAt(i) == ' ') i--;
        int length = 0;
        while (i >= 0 && s.charAt(i) != ' ') {
            length++;
            i--;
        }
        return length;
    }
}
```

### 20. Longest Common Prefix (LC 14)

**Idea:** Shrink the first string until every other string starts with it.  
**Time:** O(total characters) **Space:** O(1)

```java
class Solution {
    public String longestCommonPrefix(String[] strs) {
        String prefix = strs[0];
        for (int i = 1; i < strs.length; i++) {
            while (!strs[i].startsWith(prefix)) {
                prefix = prefix.substring(0, prefix.length() - 1);
                if (prefix.isEmpty()) return "";
            }
        }
        return prefix;
    }
}
```

### 21. Reverse Words in a String (LC 151)

**Idea:** Split the trimmed string on whitespace and rebuild the words in reverse order.  
**Time:** O(n) **Space:** O(n)

```java
class Solution {
    public String reverseWords(String s) {
        String[] words = s.trim().split("\\s+");
        StringBuilder ans = new StringBuilder();
        for (int i = words.length - 1; i >= 0; i--) {
            if (ans.length() > 0) ans.append(' ');
            ans.append(words[i]);
        }
        return ans.toString();
    }
}
```

### 22. Zigzag Conversion (LC 6)

**Idea:** Append each character to its current row and reverse direction at the top and bottom.  
**Time:** O(n) **Space:** O(n)

```java
class Solution {
    public String convert(String s, int numRows) {
        if (numRows == 1 || numRows >= s.length()) return s;
        List<StringBuilder> rows = new ArrayList<>();
        for (int i = 0; i < numRows; i++) rows.add(new StringBuilder());
        int row = 0, step = 1;
        for (char c : s.toCharArray()) {
            rows.get(row).append(c);
            if (row == 0) step = 1;
            else if (row == numRows - 1) step = -1;
            row += step;
        }
        StringBuilder ans = new StringBuilder();
        for (StringBuilder part : rows) ans.append(part);
        return ans.toString();
    }
}
```

### 23. Find the Index of the First Occurrence in a String (LC 28)

**Idea:** Build the KMP prefix table, then reuse matched-prefix information after a mismatch.  
**Time:** O(n + m) **Space:** O(m)

```java
class Solution {
    public int strStr(String haystack, String needle) {
        if (needle.isEmpty()) return 0;
        int[] lps = new int[needle.length()];
        for (int i = 1, len = 0; i < needle.length();) {
            if (needle.charAt(i) == needle.charAt(len)) lps[i++] = ++len;
            else if (len > 0) len = lps[len - 1];
            else i++;
        }
        for (int i = 0, j = 0; i < haystack.length();) {
            if (haystack.charAt(i) == needle.charAt(j)) {
                i++;
                j++;
                if (j == needle.length()) return i - j;
            } else if (j > 0) {
                j = lps[j - 1];
            } else {
                i++;
            }
        }
        return -1;
    }
}
```

### 24. Text Justification (LC 68)

**Idea:** Greedily pack each line, distribute spaces evenly, and left-justify the final line.  
**Time:** O(total characters) **Space:** O(maxWidth) extra, excluding output

```java
class Solution {
    public List<String> fullJustify(String[] words, int maxWidth) {
        List<String> ans = new ArrayList<>();
        int i = 0;
        while (i < words.length) {
            int j = i + 1, letters = words[i].length();
            while (j < words.length && letters + words[j].length() + (j - i) <= maxWidth) {
                letters += words[j++].length();
            }

            int gaps = j - i - 1;
            StringBuilder line = new StringBuilder(words[i]);
            if (j == words.length || gaps == 0) {
                for (int k = i + 1; k < j; k++) line.append(' ').append(words[k]);
                while (line.length() < maxWidth) line.append(' ');
            } else {
                int spaces = maxWidth - letters;
                int each = spaces / gaps, extra = spaces % gaps;
                for (int k = i + 1; k < j; k++) {
                    int gapWidth = each + (k - i <= extra ? 1 : 0);
                    for (int s = 0; s < gapWidth; s++) line.append(' ');
                    line.append(words[k]);
                }
            }
            ans.add(line.toString());
            i = j;
        }
        return ans;
    }
}
```

## Two Pointers

### 25. Valid Palindrome (LC 125)

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

### 26. Is Subsequence (LC 392)

**Idea:** Advance the pointer in `s` whenever the current character is found in `t`.  
**Time:** O(n) **Space:** O(1)

```java
class Solution {
    public boolean isSubsequence(String s, String t) {
        int i = 0;
        for (int j = 0; j < t.length() && i < s.length(); j++) {
            if (s.charAt(i) == t.charAt(j)) i++;
        }
        return i == s.length();
    }
}
```

### 27. Two Sum II - Input Array Is Sorted (LC 167)

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

### 28. Container With Most Water (LC 11)

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

### 29. 3Sum (LC 15)

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

## Sliding Window

### 30. Minimum Size Subarray Sum (LC 209)

**Idea:** Expand until the sum reaches the target, then shrink from the left as much as possible.  
**Time:** O(n) **Space:** O(1)

```java
class Solution {
    public int minSubArrayLen(int target, int[] nums) {
        int left = 0, sum = 0, best = Integer.MAX_VALUE;
        for (int right = 0; right < nums.length; right++) {
            sum += nums[right];
            while (sum >= target) {
                best = Math.min(best, right - left + 1);
                sum -= nums[left++];
            }
        }
        return best == Integer.MAX_VALUE ? 0 : best;
    }
}
```

### 31. Longest Substring Without Repeating Characters (LC 3)

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

### 32. Substring with Concatenation of All Words (LC 30)

**Idea:** Run one word-aligned sliding window per offset and maintain word frequencies inside the window.  
**Time:** O(n * L), where L is the word length **Space:** O(k), where k is the number of distinct words

```java
class Solution {
    public List<Integer> findSubstring(String s, String[] words) {
        List<Integer> ans = new ArrayList<>();
        int wordLength = words[0].length(), wordCount = words.length;
        Map<String, Integer> need = new HashMap<>();
        for (String word : words) need.put(word, need.getOrDefault(word, 0) + 1);

        for (int offset = 0; offset < wordLength; offset++) {
            Map<String, Integer> window = new HashMap<>();
            int left = offset, used = 0;
            for (int right = offset; right + wordLength <= s.length(); right += wordLength) {
                String word = s.substring(right, right + wordLength);
                if (!need.containsKey(word)) {
                    window.clear();
                    used = 0;
                    left = right + wordLength;
                    continue;
                }

                window.put(word, window.getOrDefault(word, 0) + 1);
                used++;
                while (window.get(word) > need.get(word)) {
                    String removed = s.substring(left, left + wordLength);
                    window.put(removed, window.get(removed) - 1);
                    left += wordLength;
                    used--;
                }
                if (used == wordCount) {
                    ans.add(left);
                    String removed = s.substring(left, left + wordLength);
                    window.put(removed, window.get(removed) - 1);
                    left += wordLength;
                    used--;
                }
            }
        }
        return ans;
    }
}
```

### 33. Minimum Window Substring (LC 76)

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

## Matrix

### 34. Valid Sudoku (LC 36)

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

### 35. Spiral Matrix (LC 54)

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

### 36. Rotate Image (LC 48)

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

### 37. Set Matrix Zeroes (LC 73)

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

### 38. Game of Life (LC 289)

**Idea:** Keep the old state in bit 0 and write the next state into bit 1, then shift every cell.  
**Time:** O(mn) **Space:** O(1)

```java
class Solution {
    public void gameOfLife(int[][] board) {
        int m = board.length, n = board[0].length;
        for (int r = 0; r < m; r++) {
            for (int c = 0; c < n; c++) {
                int live = 0;
                for (int dr = -1; dr <= 1; dr++) {
                    for (int dc = -1; dc <= 1; dc++) {
                        if (dr == 0 && dc == 0) continue;
                        int nr = r + dr, nc = c + dc;
                        if (nr >= 0 && nr < m && nc >= 0 && nc < n) {
                            live += board[nr][nc] & 1;
                        }
                    }
                }
                if (live == 3 || (live == 2 && (board[r][c] & 1) == 1)) board[r][c] |= 2;
            }
        }
        for (int[] row : board) {
            for (int c = 0; c < n; c++) row[c] >>= 1;
        }
    }
}
```

## Hashmap

### 39. Ransom Note (LC 383)

**Idea:** Count magazine letters, then consume one count for each ransom-note letter.  
**Time:** O(m + n) **Space:** O(1)

```java
class Solution {
    public boolean canConstruct(String ransomNote, String magazine) {
        int[] count = new int[26];
        for (char c : magazine.toCharArray()) count[c - 'a']++;
        for (char c : ransomNote.toCharArray()) {
            if (--count[c - 'a'] < 0) return false;
        }
        return true;
    }
}
```

### 40. Isomorphic Strings (LC 205)

**Idea:** The most recent positions of corresponding characters must always match in both strings.  
**Time:** O(n) **Space:** O(1) for the fixed character tables

```java
class Solution {
    public boolean isIsomorphic(String s, String t) {
        if (s.length() != t.length()) return false;
        int[] seenS = new int[256], seenT = new int[256];
        for (int i = 0; i < s.length(); i++) {
            char a = s.charAt(i), b = t.charAt(i);
            if (seenS[a] != seenT[b]) return false;
            seenS[a] = seenT[b] = i + 1;
        }
        return true;
    }
}
```

### 41. Word Pattern (LC 290)

**Idea:** Map each pattern character to one word while a set prevents two characters from sharing a word.  
**Time:** O(n) **Space:** O(n)

```java
class Solution {
    public boolean wordPattern(String pattern, String s) {
        String[] words = s.split(" ");
        if (pattern.length() != words.length) return false;
        Map<Character, String> map = new HashMap<>();
        Set<String> used = new HashSet<>();
        for (int i = 0; i < pattern.length(); i++) {
            char c = pattern.charAt(i);
            if (map.containsKey(c)) {
                if (!map.get(c).equals(words[i])) return false;
            } else {
                if (!used.add(words[i])) return false;
                map.put(c, words[i]);
            }
        }
        return true;
    }
}
```

### 42. Valid Anagram (LC 242)

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

### 43. Group Anagrams (LC 49)

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

### 44. Two Sum (LC 1)

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

### 45. Happy Number (LC 202)

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

### 46. Contains Duplicate II (LC 219)

**Idea:** Maintain a set containing only the previous `k` values.  
**Time:** O(n) **Space:** O(min(n, k))

```java
class Solution {
    public boolean containsNearbyDuplicate(int[] nums, int k) {
        Set<Integer> window = new HashSet<>();
        for (int i = 0; i < nums.length; i++) {
            if (i > k) window.remove(nums[i - k - 1]);
            if (!window.add(nums[i])) return true;
        }
        return false;
    }
}
```

### 47. Longest Consecutive Sequence (LC 128)

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

## Intervals

### 48. Summary Ranges (LC 228)

**Idea:** Extend each maximal consecutive run and format its start and end.  
**Time:** O(n) **Space:** O(1) extra, excluding output

```java
class Solution {
    public List<String> summaryRanges(int[] nums) {
        List<String> ans = new ArrayList<>();
        for (int i = 0; i < nums.length;) {
            int start = i;
            while (i + 1 < nums.length && (long) nums[i + 1] == (long) nums[i] + 1) i++;
            if (start == i) ans.add(Integer.toString(nums[i]));
            else ans.add(nums[start] + "->" + nums[i]);
            i++;
        }
        return ans;
    }
}
```

### 49. Merge Intervals (LC 56)

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

### 50. Insert Interval (LC 57)

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

### 51. Minimum Number of Arrows to Burst Balloons (LC 452)

**Idea:** Sort by end coordinate and shoot a new arrow only when the next balloon starts after the current arrow.  
**Time:** O(n log n) **Space:** O(log n) to O(n), depending on the sort

```java
class Solution {
    public int findMinArrowShots(int[][] points) {
        Arrays.sort(points, (a, b) -> Integer.compare(a[1], b[1]));
        int arrows = 1;
        long end = points[0][1];
        for (int i = 1; i < points.length; i++) {
            if (points[i][0] > end) {
                arrows++;
                end = points[i][1];
            }
        }
        return arrows;
    }
}
```

## Stack

### 52. Valid Parentheses (LC 20)

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

### 53. Simplify Path (LC 71)

**Idea:** Treat normal path components as stack entries, ignore `.`, and pop for `..`.  
**Time:** O(n) **Space:** O(n)

```java
class Solution {
    public String simplifyPath(String path) {
        Deque<String> stack = new ArrayDeque<>();
        for (String part : path.split("/")) {
            if (part.isEmpty() || part.equals(".")) continue;
            if (part.equals("..")) {
                if (!stack.isEmpty()) stack.removeLast();
            } else {
                stack.addLast(part);
            }
        }
        return "/" + String.join("/", stack);
    }
}
```

### 54. Min Stack (LC 155)

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

### 55. Evaluate Reverse Polish Notation (LC 150)

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

### 56. Basic Calculator (LC 224)

**Idea:** Accumulate signed numbers; parentheses save the outer result and sign on a stack.  
**Time:** O(n) **Space:** O(n)

```java
class Solution {
    public int calculate(String s) {
        Deque<Integer> stack = new ArrayDeque<>();
        int result = 0, number = 0, sign = 1;
        for (char c : s.toCharArray()) {
            if (Character.isDigit(c)) {
                number = number * 10 + c - '0';
            } else if (c == '+' || c == '-') {
                result += sign * number;
                number = 0;
                sign = c == '+' ? 1 : -1;
            } else if (c == '(') {
                stack.push(result);
                stack.push(sign);
                result = 0;
                sign = 1;
            } else if (c == ')') {
                result += sign * number;
                number = 0;
                result *= stack.pop();
                result += stack.pop();
            }
        }
        return result + sign * number;
    }
}
```

## Linked List

### 57. Linked List Cycle (LC 141)

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

### 58. Add Two Numbers (LC 2)

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

### 59. Merge Two Sorted Lists (LC 21)

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

### 60. Copy List with Random Pointer (LC 138)

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

### 61. Reverse Linked List II (LC 92)

**Idea:** Move each node after `left` to the front of the reversing segment.  
**Time:** O(n) **Space:** O(1)

```java
class Solution {
    public ListNode reverseBetween(ListNode head, int left, int right) {
        ListNode dummy = new ListNode(0);
        dummy.next = head;
        ListNode before = dummy;
        for (int i = 1; i < left; i++) before = before.next;
        ListNode first = before.next;
        for (int i = 0; i < right - left; i++) {
            ListNode moved = first.next;
            first.next = moved.next;
            moved.next = before.next;
            before.next = moved;
        }
        return dummy.next;
    }
}
```

### 62. Reverse Nodes in k-Group (LC 25)

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

### 63. Remove Nth Node From End of List (LC 19)

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

### 64. Remove Duplicates from Sorted List II (LC 82)

**Idea:** Skip an entire value group whenever that value appears more than once.  
**Time:** O(n) **Space:** O(1)

```java
class Solution {
    public ListNode deleteDuplicates(ListNode head) {
        ListNode dummy = new ListNode(0);
        dummy.next = head;
        ListNode prev = dummy;
        while (head != null) {
            if (head.next != null && head.val == head.next.val) {
                int value = head.val;
                while (head != null && head.val == value) head = head.next;
                prev.next = head;
            } else {
                prev = head;
                head = head.next;
            }
        }
        return dummy.next;
    }
}
```

### 65. Rotate List (LC 61)

**Idea:** Make the list circular, find the new tail, and break the circle after `n - k mod n` nodes.  
**Time:** O(n) **Space:** O(1)

```java
class Solution {
    public ListNode rotateRight(ListNode head, int k) {
        if (head == null || head.next == null || k == 0) return head;
        int n = 1;
        ListNode tail = head;
        while (tail.next != null) {
            tail = tail.next;
            n++;
        }
        k %= n;
        if (k == 0) return head;
        tail.next = head;
        int steps = n - k;
        while (steps-- > 0) tail = tail.next;
        ListNode newHead = tail.next;
        tail.next = null;
        return newHead;
    }
}
```

### 66. Partition List (LC 86)

**Idea:** Build stable `less` and `greater-or-equal` chains, then join them.  
**Time:** O(n) **Space:** O(1)

```java
class Solution {
    public ListNode partition(ListNode head, int x) {
        ListNode lessDummy = new ListNode(0), moreDummy = new ListNode(0);
        ListNode less = lessDummy, more = moreDummy;
        while (head != null) {
            if (head.val < x) {
                less.next = head;
                less = less.next;
            } else {
                more.next = head;
                more = more.next;
            }
            head = head.next;
        }
        more.next = null;
        less.next = moreDummy.next;
        return lessDummy.next;
    }
}
```

### 67. LRU Cache (LC 146)

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

## Binary Tree General

### 68. Maximum Depth of Binary Tree (LC 104)

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

### 69. Same Tree (LC 100)

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

### 70. Invert Binary Tree (LC 226)

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

### 71. Symmetric Tree (LC 101)

**Idea:** Two subtrees are mirrors when their roots match and their outer and inner children mirror each other.  
**Time:** O(n) **Space:** O(h)

```java
class Solution {
    public boolean isSymmetric(TreeNode root) {
        return root == null || mirror(root.left, root.right);
    }

    private boolean mirror(TreeNode a, TreeNode b) {
        if (a == null || b == null) return a == b;
        return a.val == b.val && mirror(a.left, b.right) && mirror(a.right, b.left);
    }
}
```

### 72. Construct Binary Tree from Preorder and Inorder Traversal (LC 105)

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

### 73. Construct Binary Tree from Inorder and Postorder Traversal (LC 106)

**Idea:** Read postorder backward for roots; after splitting inorder, build the right subtree before the left.  
**Time:** O(n) **Space:** O(n)

```java
class Solution {
    private int postorderIndex;
    private Map<Integer, Integer> inorderIndex;

    public TreeNode buildTree(int[] inorder, int[] postorder) {
        postorderIndex = postorder.length - 1;
        inorderIndex = new HashMap<>();
        for (int i = 0; i < inorder.length; i++) inorderIndex.put(inorder[i], i);
        return build(postorder, 0, inorder.length - 1);
    }

    private TreeNode build(int[] postorder, int left, int right) {
        if (left > right) return null;
        int value = postorder[postorderIndex--];
        TreeNode root = new TreeNode(value);
        int mid = inorderIndex.get(value);
        root.right = build(postorder, mid + 1, right);
        root.left = build(postorder, left, mid - 1);
        return root;
    }
}
```

### 74. Populating Next Right Pointers in Each Node II (LC 117)

**Idea:** Traverse one level through existing `next` links while a dummy node builds the next level.  
**Time:** O(n) **Space:** O(1)

```java
class Solution {
    public Node connect(Node root) {
        Node level = root;
        while (level != null) {
            Node dummy = new Node(0), tail = dummy;
            for (Node cur = level; cur != null; cur = cur.next) {
                if (cur.left != null) {
                    tail.next = cur.left;
                    tail = tail.next;
                }
                if (cur.right != null) {
                    tail.next = cur.right;
                    tail = tail.next;
                }
            }
            level = dummy.next;
        }
        return root;
    }
}
```

### 75. Flatten Binary Tree to Linked List (LC 114)

**Idea:** Process nodes in reverse preorder so each node can point right to the previously processed node.  
**Time:** O(n) **Space:** O(h)

```java
class Solution {
    private TreeNode next;

    public void flatten(TreeNode root) {
        if (root == null) return;
        flatten(root.right);
        flatten(root.left);
        root.right = next;
        root.left = null;
        next = root;
    }
}
```

### 76. Path Sum (LC 112)

**Idea:** Subtract each node value and accept a leaf exactly when the remaining sum equals that leaf.  
**Time:** O(n) **Space:** O(h)

```java
class Solution {
    public boolean hasPathSum(TreeNode root, int targetSum) {
        if (root == null) return false;
        if (root.left == null && root.right == null) return targetSum == root.val;
        int remain = targetSum - root.val;
        return hasPathSum(root.left, remain) || hasPathSum(root.right, remain);
    }
}
```

### 77. Sum Root to Leaf Numbers (LC 129)

**Idea:** Carry the decimal number formed along the current root-to-node path.  
**Time:** O(n) **Space:** O(h)

```java
class Solution {
    public int sumNumbers(TreeNode root) {
        return dfs(root, 0);
    }

    private int dfs(TreeNode node, int value) {
        if (node == null) return 0;
        value = value * 10 + node.val;
        if (node.left == null && node.right == null) return value;
        return dfs(node.left, value) + dfs(node.right, value);
    }
}
```

### 78. Binary Tree Maximum Path Sum (LC 124)

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

### 79. Binary Search Tree Iterator (LC 173)

**Idea:** Keep the path to the next smallest node on a stack and push left spines lazily.  
**Time:** O(1) amortized for `next`, O(1) for `hasNext` **Space:** O(h)

```java
class BSTIterator {
    private final Deque<TreeNode> stack = new ArrayDeque<>();

    public BSTIterator(TreeNode root) {
        pushLeft(root);
    }

    public int next() {
        TreeNode node = stack.pop();
        pushLeft(node.right);
        return node.val;
    }

    public boolean hasNext() {
        return !stack.isEmpty();
    }

    private void pushLeft(TreeNode node) {
        while (node != null) {
            stack.push(node);
            node = node.left;
        }
    }
}
```

### 80. Count Complete Tree Nodes (LC 222)

**Idea:** Equal leftmost and rightmost heights identify a perfect subtree; otherwise recurse into both sides.  
**Time:** O(log^2 n) **Space:** O(log n)

```java
class Solution {
    public int countNodes(TreeNode root) {
        if (root == null) return 0;
        int left = leftHeight(root), right = rightHeight(root);
        if (left == right) return (int) ((1L << left) - 1);
        return 1 + countNodes(root.left) + countNodes(root.right);
    }

    private int leftHeight(TreeNode node) {
        int h = 0;
        while (node != null) {
            h++;
            node = node.left;
        }
        return h;
    }

    private int rightHeight(TreeNode node) {
        int h = 0;
        while (node != null) {
            h++;
            node = node.right;
        }
        return h;
    }
}
```

### 81. Lowest Common Ancestor of a Binary Tree (LC 236)

**Idea:** If `p` and `q` are found in different subtrees, the current node is their lowest common ancestor.  
**Time:** O(n) **Space:** O(h)

```java
class Solution {
    public TreeNode lowestCommonAncestor(TreeNode root, TreeNode p, TreeNode q) {
        if (root == null || root == p || root == q) return root;
        TreeNode left = lowestCommonAncestor(root.left, p, q);
        TreeNode right = lowestCommonAncestor(root.right, p, q);
        if (left != null && right != null) return root;
        return left != null ? left : right;
    }
}
```

## Binary Tree BFS

### 82. Binary Tree Right Side View (LC 199)

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

### 83. Average of Levels in Binary Tree (LC 637)

**Idea:** Sum each BFS level with `long`, then divide by its node count.  
**Time:** O(n) **Space:** O(n)

```java
class Solution {
    public List<Double> averageOfLevels(TreeNode root) {
        List<Double> ans = new ArrayList<>();
        Queue<TreeNode> queue = new ArrayDeque<>();
        queue.offer(root);
        while (!queue.isEmpty()) {
            int size = queue.size();
            long sum = 0;
            for (int i = 0; i < size; i++) {
                TreeNode node = queue.poll();
                sum += node.val;
                if (node.left != null) queue.offer(node.left);
                if (node.right != null) queue.offer(node.right);
            }
            ans.add(sum / (double) size);
        }
        return ans;
    }
}
```

### 84. Binary Tree Level Order Traversal (LC 102)

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

### 85. Binary Tree Zigzag Level Order Traversal (LC 103)

**Idea:** BFS normally, but insert values at opposite ends of a linked list on alternating levels.  
**Time:** O(n) **Space:** O(n)

```java
class Solution {
    public List<List<Integer>> zigzagLevelOrder(TreeNode root) {
        List<List<Integer>> ans = new ArrayList<>();
        if (root == null) return ans;
        Queue<TreeNode> queue = new ArrayDeque<>();
        queue.offer(root);
        boolean leftToRight = true;
        while (!queue.isEmpty()) {
            int size = queue.size();
            LinkedList<Integer> level = new LinkedList<>();
            for (int i = 0; i < size; i++) {
                TreeNode node = queue.poll();
                if (leftToRight) level.addLast(node.val);
                else level.addFirst(node.val);
                if (node.left != null) queue.offer(node.left);
                if (node.right != null) queue.offer(node.right);
            }
            ans.add(level);
            leftToRight = !leftToRight;
        }
        return ans;
    }
}
```

## Binary Search Tree

### 86. Minimum Absolute Difference in BST (LC 530)

**Idea:** Inorder traversal visits values in sorted order, so only adjacent values need comparison.  
**Time:** O(n) **Space:** O(h)

```java
class Solution {
    private Integer previous;
    private int best = Integer.MAX_VALUE;

    public int getMinimumDifference(TreeNode root) {
        inorder(root);
        return best;
    }

    private void inorder(TreeNode node) {
        if (node == null) return;
        inorder(node.left);
        if (previous != null) best = Math.min(best, node.val - previous);
        previous = node.val;
        inorder(node.right);
    }
}
```

### 87. Kth Smallest Element in a BST (LC 230)

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

### 88. Validate Binary Search Tree (LC 98)

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

## Graph General

### 89. Number of Islands (LC 200)

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

### 90. Surrounded Regions (LC 130)

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

### 91. Clone Graph (LC 133)

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

### 92. Evaluate Division (LC 399)

**Idea:** Model equations as weighted directed edges and DFS from each query numerator to denominator.  
**Time:** O(E + Q(V + E)) worst case **Space:** O(V + E)

```java
class Solution {
    private static class Edge {
        String to;
        double weight;
        Edge(String to, double weight) { this.to = to; this.weight = weight; }
    }

    public double[] calcEquation(List<List<String>> equations, double[] values,
                                 List<List<String>> queries) {
        Map<String, List<Edge>> graph = new HashMap<>();
        for (int i = 0; i < equations.size(); i++) {
            String a = equations.get(i).get(0), b = equations.get(i).get(1);
            graph.computeIfAbsent(a, k -> new ArrayList<>()).add(new Edge(b, values[i]));
            graph.computeIfAbsent(b, k -> new ArrayList<>()).add(new Edge(a, 1.0 / values[i]));
        }

        double[] ans = new double[queries.size()];
        for (int i = 0; i < queries.size(); i++) {
            String start = queries.get(i).get(0), target = queries.get(i).get(1);
            if (!graph.containsKey(start) || !graph.containsKey(target)) ans[i] = -1.0;
            else ans[i] = dfs(start, target, 1.0, graph, new HashSet<>());
        }
        return ans;
    }

    private double dfs(String node, String target, double value,
                       Map<String, List<Edge>> graph, Set<String> seen) {
        if (node.equals(target)) return value;
        seen.add(node);
        for (Edge edge : graph.get(node)) {
            if (seen.contains(edge.to)) continue;
            double result = dfs(edge.to, target, value * edge.weight, graph, seen);
            if (result != -1.0) return result;
        }
        return -1.0;
    }
}
```

### 93. Course Schedule (LC 207)

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

### 94. Course Schedule II (LC 210)

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

## Graph BFS

### 95. Snakes and Ladders (LC 909)

**Idea:** BFS over square numbers; each die roll follows any snake or ladder before entering the queue.  
**Time:** O(n^2) **Space:** O(n^2)

```java
class Solution {
    public int snakesAndLadders(int[][] board) {
        int n = board.length, target = n * n;
        boolean[] seen = new boolean[target + 1];
        Queue<Integer> queue = new ArrayDeque<>();
        queue.offer(1);
        seen[1] = true;
        int moves = 0;

        while (!queue.isEmpty()) {
            for (int size = queue.size(); size > 0; size--) {
                int square = queue.poll();
                if (square == target) return moves;
                for (int next = square + 1; next <= Math.min(square + 6, target); next++) {
                    int[] position = position(next, n);
                    int destination = board[position[0]][position[1]] == -1
                            ? next : board[position[0]][position[1]];
                    if (!seen[destination]) {
                        seen[destination] = true;
                        queue.offer(destination);
                    }
                }
            }
            moves++;
        }
        return -1;
    }

    private int[] position(int square, int n) {
        int rowFromBottom = (square - 1) / n;
        int row = n - 1 - rowFromBottom;
        int col = (square - 1) % n;
        if ((rowFromBottom & 1) == 1) col = n - 1 - col;
        return new int[]{row, col};
    }
}
```

### 96. Minimum Genetic Mutation (LC 433)

**Idea:** BFS through valid one-character mutations contained in the bank.  
**Time:** O(N * L * 4) **Space:** O(N), with gene length L = 8

```java
class Solution {
    public int minMutation(String startGene, String endGene, String[] bank) {
        if (startGene.equals(endGene)) return 0;
        Set<String> remaining = new HashSet<>(Arrays.asList(bank));
        if (!remaining.contains(endGene)) return -1;
        Queue<String> queue = new ArrayDeque<>();
        queue.offer(startGene);
        remaining.remove(startGene);
        char[] choices = {'A', 'C', 'G', 'T'};
        int steps = 0;

        while (!queue.isEmpty()) {
            for (int size = queue.size(); size > 0; size--) {
                String gene = queue.poll();
                if (gene.equals(endGene)) return steps;
                char[] chars = gene.toCharArray();
                for (int i = 0; i < chars.length; i++) {
                    char original = chars[i];
                    for (char c : choices) {
                        chars[i] = c;
                        String next = new String(chars);
                        if (remaining.remove(next)) queue.offer(next);
                    }
                    chars[i] = original;
                }
            }
            steps++;
        }
        return -1;
    }
}
```

### 97. Word Ladder (LC 127)

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

## Trie

### 98. Implement Trie (Prefix Tree) (LC 208)

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

### 99. Design Add and Search Words Data Structure (LC 211)

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

### 100. Word Search II (LC 212)

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

## Backtracking

### 101. Letter Combinations of a Phone Number (LC 17)

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

### 102. Combinations (LC 77)

**Idea:** Choose increasing numbers and stop early when too few values remain to fill the combination.  
**Time:** O(C(n, k) * k) **Space:** O(k)

```java
class Solution {
    public List<List<Integer>> combine(int n, int k) {
        List<List<Integer>> ans = new ArrayList<>();
        build(1, n, k, new ArrayList<>(), ans);
        return ans;
    }

    private void build(int start, int n, int k, List<Integer> path, List<List<Integer>> ans) {
        if (path.size() == k) {
            ans.add(new ArrayList<>(path));
            return;
        }
        int need = k - path.size();
        for (int value = start; value <= n - need + 1; value++) {
            path.add(value);
            build(value + 1, n, k, path, ans);
            path.remove(path.size() - 1);
        }
    }
}
```

### 103. Permutations (LC 46)

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

### 104. Combination Sum (LC 39)

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

### 105. N-Queens II (LC 52)

**Idea:** Place one queen per row while marking occupied columns and both diagonal families.  
**Time:** O(n!) **Space:** O(n)

```java
class Solution {
    public int totalNQueens(int n) {
        return place(0, n, new boolean[n], new boolean[2 * n], new boolean[2 * n]);
    }

    private int place(int row, int n, boolean[] columns, boolean[] diag1, boolean[] diag2) {
        if (row == n) return 1;
        int count = 0;
        for (int col = 0; col < n; col++) {
            int d1 = row - col + n, d2 = row + col;
            if (columns[col] || diag1[d1] || diag2[d2]) continue;
            columns[col] = diag1[d1] = diag2[d2] = true;
            count += place(row + 1, n, columns, diag1, diag2);
            columns[col] = diag1[d1] = diag2[d2] = false;
        }
        return count;
    }
}
```

### 106. Generate Parentheses (LC 22)

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

### 107. Word Search (LC 79)

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

## Divide & Conquer

### 108. Convert Sorted Array to Binary Search Tree (LC 108)

**Idea:** Choose the middle value as root so both recursively built subtrees stay balanced.  
**Time:** O(n) **Space:** O(log n)

```java
class Solution {
    public TreeNode sortedArrayToBST(int[] nums) {
        return build(nums, 0, nums.length - 1);
    }

    private TreeNode build(int[] nums, int left, int right) {
        if (left > right) return null;
        int mid = left + (right - left) / 2;
        TreeNode root = new TreeNode(nums[mid]);
        root.left = build(nums, left, mid - 1);
        root.right = build(nums, mid + 1, right);
        return root;
    }
}
```

### 109. Sort List (LC 148)

**Idea:** Split with slow and fast pointers, recursively sort both halves, then merge them.  
**Time:** O(n log n) **Space:** O(log n)

```java
class Solution {
    public ListNode sortList(ListNode head) {
        if (head == null || head.next == null) return head;
        ListNode slow = head, fast = head.next;
        while (fast != null && fast.next != null) {
            slow = slow.next;
            fast = fast.next.next;
        }
        ListNode right = slow.next;
        slow.next = null;
        return merge(sortList(head), sortList(right));
    }

    private ListNode merge(ListNode a, ListNode b) {
        ListNode dummy = new ListNode(0), tail = dummy;
        while (a != null && b != null) {
            if (a.val <= b.val) {
                tail.next = a;
                a = a.next;
            } else {
                tail.next = b;
                b = b.next;
            }
            tail = tail.next;
        }
        tail.next = a != null ? a : b;
        return dummy.next;
    }
}
```

### 110. Construct Quad Tree (LC 427)

**Idea:** Return a leaf for a uniform square; otherwise divide it into four equal quadrants.  
**Time:** O(n^2 log n) worst case **Space:** O(log n) excluding output

```java
class Solution {
    public Node construct(int[][] grid) {
        return build(grid, 0, 0, grid.length);
    }

    private Node build(int[][] grid, int row, int col, int size) {
        int first = grid[row][col];
        boolean uniform = true;
        for (int r = row; r < row + size && uniform; r++) {
            for (int c = col; c < col + size; c++) {
                if (grid[r][c] != first) {
                    uniform = false;
                    break;
                }
            }
        }
        if (uniform) return new Node(first == 1, true, null, null, null, null);
        int half = size / 2;
        return new Node(true, false,
                build(grid, row, col, half),
                build(grid, row, col + half, half),
                build(grid, row + half, col, half),
                build(grid, row + half, col + half, half));
    }
}
```

### 111. Merge k Sorted Lists (LC 23)

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

## Kadane's Algorithm

### 112. Maximum Subarray (LC 53)

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

### 113. Maximum Sum Circular Subarray (LC 918)

**Idea:** The answer is either a normal maximum subarray or total sum minus the minimum subarray.  
**Time:** O(n) **Space:** O(1)

```java
class Solution {
    public int maxSubarraySumCircular(int[] nums) {
        int total = nums[0];
        int maxEnding = nums[0], maxSum = nums[0];
        int minEnding = nums[0], minSum = nums[0];
        for (int i = 1; i < nums.length; i++) {
            maxEnding = Math.max(nums[i], maxEnding + nums[i]);
            maxSum = Math.max(maxSum, maxEnding);
            minEnding = Math.min(nums[i], minEnding + nums[i]);
            minSum = Math.min(minSum, minEnding);
            total += nums[i];
        }
        return maxSum < 0 ? maxSum : Math.max(maxSum, total - minSum);
    }
}
```

## Binary Search

### 114. Search Insert Position (LC 35)

**Idea:** Find the first index whose value is greater than or equal to the target.  
**Time:** O(log n) **Space:** O(1)

```java
class Solution {
    public int searchInsert(int[] nums, int target) {
        int left = 0, right = nums.length;
        while (left < right) {
            int mid = left + (right - left) / 2;
            if (nums[mid] < target) left = mid + 1;
            else right = mid;
        }
        return left;
    }
}
```

### 115. Search a 2D Matrix (LC 74)

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

### 116. Find Peak Element (LC 162)

**Idea:** Follow the rising slope; a peak must exist in that direction.  
**Time:** O(log n) **Space:** O(1)

```java
class Solution {
    public int findPeakElement(int[] nums) {
        int left = 0, right = nums.length - 1;
        while (left < right) {
            int mid = left + (right - left) / 2;
            if (nums[mid] > nums[mid + 1]) right = mid;
            else left = mid + 1;
        }
        return left;
    }
}
```

### 117. Search in Rotated Sorted Array (LC 33)

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

### 118. Find First and Last Position of Element in Sorted Array (LC 34)

**Idea:** Use two lower-bound searches: one for `target` and one for the first value greater than it.  
**Time:** O(log n) **Space:** O(1)

```java
class Solution {
    public int[] searchRange(int[] nums, int target) {
        int first = lowerBound(nums, target);
        if (first == nums.length || nums[first] != target) return new int[]{-1, -1};
        int last = lowerBound(nums, (long) target + 1) - 1;
        return new int[]{first, last};
    }

    private int lowerBound(int[] nums, long target) {
        int left = 0, right = nums.length;
        while (left < right) {
            int mid = left + (right - left) / 2;
            if (nums[mid] < target) left = mid + 1;
            else right = mid;
        }
        return left;
    }
}
```

### 119. Find Minimum in Rotated Sorted Array (LC 153)

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

### 120. Median of Two Sorted Arrays (LC 4)

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

## Heap

### 121. Kth Largest Element in an Array (LC 215)

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

### 122. IPO (LC 502)

**Idea:** Sort projects by required capital and repeatedly choose the largest profit currently affordable.  
**Time:** O(n log n + k log n) **Space:** O(n)

```java
class Solution {
    public int findMaximizedCapital(int k, int w, int[] profits, int[] capital) {
        int n = profits.length;
        int[][] projects = new int[n][2];
        for (int i = 0; i < n; i++) {
            projects[i][0] = capital[i];
            projects[i][1] = profits[i];
        }
        Arrays.sort(projects, Comparator.comparingInt(project -> project[0]));
        PriorityQueue<Integer> available = new PriorityQueue<>(Collections.reverseOrder());
        int index = 0;
        while (k-- > 0) {
            while (index < n && projects[index][0] <= w) {
                available.offer(projects[index++][1]);
            }
            if (available.isEmpty()) break;
            w += available.poll();
        }
        return w;
    }
}
```

### 123. Find K Pairs with Smallest Sums (LC 373)

**Idea:** Seed a min-heap with each relevant row's first pair, then advance only the row that was popped.  
**Time:** O(k log(min(m, k))) **Space:** O(min(m, k))

```java
class Solution {
    public List<List<Integer>> kSmallestPairs(int[] nums1, int[] nums2, int k) {
        List<List<Integer>> answer = new ArrayList<>();
        if (nums1.length == 0 || nums2.length == 0 || k == 0) return answer;
        PriorityQueue<int[]> heap = new PriorityQueue<>((a, b) ->
                Long.compare((long) nums1[a[0]] + nums2[a[1]],
                             (long) nums1[b[0]] + nums2[b[1]]));
        for (int i = 0; i < Math.min(nums1.length, k); i++) {
            heap.offer(new int[]{i, 0});
        }
        while (k-- > 0 && !heap.isEmpty()) {
            int[] pair = heap.poll();
            int i = pair[0], j = pair[1];
            answer.add(Arrays.asList(nums1[i], nums2[j]));
            if (j + 1 < nums2.length) heap.offer(new int[]{i, j + 1});
        }
        return answer;
    }
}
```

### 124. Find Median from Data Stream (LC 295)

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

## Bit Manipulation

### 125. Add Binary (LC 67)

**Idea:** Add from right to left while carrying exactly as in decimal addition.  
**Time:** O(m + n) **Space:** O(m + n)

```java
class Solution {
    public String addBinary(String a, String b) {
        StringBuilder result = new StringBuilder();
        int i = a.length() - 1, j = b.length() - 1, carry = 0;
        while (i >= 0 || j >= 0 || carry != 0) {
            int sum = carry;
            if (i >= 0) sum += a.charAt(i--) - '0';
            if (j >= 0) sum += b.charAt(j--) - '0';
            result.append(sum & 1);
            carry = sum >> 1;
        }
        return result.reverse().toString();
    }
}
```

### 126. Reverse Bits (LC 190)

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

### 127. Number of 1 Bits (LC 191)

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

### 128. Single Number (LC 136)

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

### 129. Single Number II (LC 137)

**Idea:** Track bits seen once and twice; a third occurrence clears the bit from both states.  
**Time:** O(n) **Space:** O(1)

```java
class Solution {
    public int singleNumber(int[] nums) {
        int once = 0, twice = 0;
        for (int value : nums) {
            once = (once ^ value) & ~twice;
            twice = (twice ^ value) & ~once;
        }
        return once;
    }
}
```

### 130. Bitwise AND of Numbers Range (LC 201)

**Idea:** Remove rightmost set bits from the upper bound until both bounds share the same prefix.  
**Time:** O(log right) **Space:** O(1)

```java
class Solution {
    public int rangeBitwiseAnd(int left, int right) {
        while (left < right) right &= right - 1;
        return right;
    }
}
```

## Math

### 131. Palindrome Number (LC 9)

**Idea:** Reverse only the last half of the digits and compare it with the first half.  
**Time:** O(log x) **Space:** O(1)

```java
class Solution {
    public boolean isPalindrome(int x) {
        if (x < 0 || (x % 10 == 0 && x != 0)) return false;
        int reversedHalf = 0;
        while (x > reversedHalf) {
            reversedHalf = reversedHalf * 10 + x % 10;
            x /= 10;
        }
        return x == reversedHalf || x == reversedHalf / 10;
    }
}
```

### 132. Plus One (LC 66)

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

### 133. Factorial Trailing Zeroes (LC 172)

**Idea:** Count factors of five contributed by 5, 25, 125, and so on.  
**Time:** O(log5 n) **Space:** O(1)

```java
class Solution {
    public int trailingZeroes(int n) {
        int count = 0;
        while (n > 0) {
            n /= 5;
            count += n;
        }
        return count;
    }
}
```

### 134. Sqrt(x) (LC 69)

**Idea:** Binary-search the largest integer whose square does not exceed `x`.  
**Time:** O(log x) **Space:** O(1)

```java
class Solution {
    public int mySqrt(int x) {
        if (x < 2) return x;
        long left = 1, right = x / 2L, answer = 1;
        while (left <= right) {
            long mid = left + (right - left) / 2;
            if (mid * mid <= x) {
                answer = mid;
                left = mid + 1;
            } else {
                right = mid - 1;
            }
        }
        return (int) answer;
    }
}
```

### 135. Pow(x, n) (LC 50)

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

### 136. Max Points on a Line (LC 149)

**Idea:** For each anchor, normalize every slope by its greatest common divisor and count equal slopes.  
**Time:** O(n^2) **Space:** O(n)

```java
class Solution {
    public int maxPoints(int[][] points) {
        if (points.length == 0) return 0;
        int answer = 1;
        for (int i = 0; i < points.length; i++) {
            Map<String, Integer> slopes = new HashMap<>();
            int bestFromAnchor = 0;
            for (int j = i + 1; j < points.length; j++) {
                int dx = points[j][0] - points[i][0];
                int dy = points[j][1] - points[i][1];
                if (dx == 0) {
                    dy = 1;
                } else if (dy == 0) {
                    dx = 1;
                } else {
                    int divisor = gcd(Math.abs(dx), Math.abs(dy));
                    dx /= divisor;
                    dy /= divisor;
                    if (dx < 0) {
                        dx = -dx;
                        dy = -dy;
                    }
                }
                String key = dy + "/" + dx;
                int count = slopes.getOrDefault(key, 0) + 1;
                slopes.put(key, count);
                bestFromAnchor = Math.max(bestFromAnchor, count);
            }
            answer = Math.max(answer, bestFromAnchor + 1);
        }
        return answer;
    }

    private int gcd(int a, int b) {
        while (b != 0) {
            int temp = a % b;
            a = b;
            b = temp;
        }
        return a;
    }
}
```

## 1D Dynamic Programming

### 137. Climbing Stairs (LC 70)

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

### 138. House Robber (LC 198)

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

### 139. Word Break (LC 139)

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

### 140. Coin Change (LC 322)

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

### 141. Longest Increasing Subsequence (LC 300)

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

## Multidimensional Dynamic Programming

### 142. Triangle (LC 120)

**Idea:** Fold the triangle upward with a one-dimensional array of best costs below each position.  
**Time:** O(n^2) **Space:** O(n)

```java
class Solution {
    public int minimumTotal(List<List<Integer>> triangle) {
        int n = triangle.size();
        int[] dp = new int[n + 1];
        for (int row = n - 1; row >= 0; row--) {
            for (int col = 0; col <= row; col++) {
                dp[col] = triangle.get(row).get(col) + Math.min(dp[col], dp[col + 1]);
            }
        }
        return dp[0];
    }
}
```

### 143. Minimum Path Sum (LC 64)

**Idea:** Reuse the grid so each cell stores its value plus the cheaper cost from above or left.  
**Time:** O(mn) **Space:** O(1)

```java
class Solution {
    public int minPathSum(int[][] grid) {
        for (int row = 0; row < grid.length; row++) {
            for (int col = 0; col < grid[0].length; col++) {
                if (row == 0 && col == 0) continue;
                int fromAbove = row > 0 ? grid[row - 1][col] : Integer.MAX_VALUE;
                int fromLeft = col > 0 ? grid[row][col - 1] : Integer.MAX_VALUE;
                grid[row][col] += Math.min(fromAbove, fromLeft);
            }
        }
        return grid[grid.length - 1][grid[0].length - 1];
    }
}
```

### 144. Unique Paths II (LC 63)

**Idea:** Accumulate path counts in one row, resetting a cell to zero whenever it is blocked.  
**Time:** O(mn) **Space:** O(n)

```java
class Solution {
    public int uniquePathsWithObstacles(int[][] obstacleGrid) {
        int cols = obstacleGrid[0].length;
        int[] dp = new int[cols];
        dp[0] = 1;
        for (int[] row : obstacleGrid) {
            for (int col = 0; col < cols; col++) {
                if (row[col] == 1) dp[col] = 0;
                else if (col > 0) dp[col] += dp[col - 1];
            }
        }
        return dp[cols - 1];
    }
}
```

### 145. Longest Palindromic Substring (LC 5)

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

### 146. Interleaving String (LC 97)

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

### 147. Edit Distance (LC 72)

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

### 148. Best Time to Buy and Sell Stock III (LC 123)

**Idea:** Track the best states after the first buy, first sale, second buy, and second sale.  
**Time:** O(n) **Space:** O(1)

```java
class Solution {
    public int maxProfit(int[] prices) {
        int firstBuy = Integer.MIN_VALUE, firstSell = 0;
        int secondBuy = Integer.MIN_VALUE, secondSell = 0;
        for (int price : prices) {
            firstBuy = Math.max(firstBuy, -price);
            firstSell = Math.max(firstSell, firstBuy + price);
            secondBuy = Math.max(secondBuy, firstSell - price);
            secondSell = Math.max(secondSell, secondBuy + price);
        }
        return secondSell;
    }
}
```

### 149. Best Time to Buy and Sell Stock IV (LC 188)

**Idea:** Keep buy and sell states for every allowed transaction count, with a greedy shortcut for unlimited trades.  
**Time:** O(kn) **Space:** O(k)

```java
class Solution {
    public int maxProfit(int k, int[] prices) {
        int n = prices.length;
        if (k >= n / 2) {
            int profit = 0;
            for (int i = 1; i < n; i++) {
                if (prices[i] > prices[i - 1]) profit += prices[i] - prices[i - 1];
            }
            return profit;
        }
        int[] buy = new int[k + 1];
        int[] sell = new int[k + 1];
        Arrays.fill(buy, Integer.MIN_VALUE / 2);
        for (int price : prices) {
            for (int transaction = 1; transaction <= k; transaction++) {
                buy[transaction] = Math.max(buy[transaction], sell[transaction - 1] - price);
                sell[transaction] = Math.max(sell[transaction], buy[transaction] + price);
            }
        }
        return sell[k];
    }
}
```

### 150. Maximal Square (LC 221)

**Idea:** A square ending at a `1` extends the minimum square ending above, left, or diagonally above-left.  
**Time:** O(mn) **Space:** O(n)

```java
class Solution {
    public int maximalSquare(char[][] matrix) {
        int cols = matrix[0].length;
        int[] dp = new int[cols + 1];
        int largestSide = 0;
        for (int row = 1; row <= matrix.length; row++) {
            int diagonal = 0;
            for (int col = 1; col <= cols; col++) {
                int above = dp[col];
                if (matrix[row - 1][col - 1] == '1') {
                    dp[col] = 1 + Math.min(diagonal, Math.min(dp[col], dp[col - 1]));
                    largestSide = Math.max(largestSide, dp[col]);
                } else {
                    dp[col] = 0;
                }
                diagonal = above;
            }
        }
        return largestSide * largestSide;
    }
}
```
