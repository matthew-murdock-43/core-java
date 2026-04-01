# LeetCode 75 - Java Solutions

This document covers the current LeetCode 75 study plan list and provides concise Java solutions for each problem.

Notes:
- `ListNode`, `TreeNode`, and the `guess(int num)` API are assumed to be provided by LeetCode.
- For brevity, helper comments are minimal and code is written in standard LeetCode style.
- Each solution is original, concise, and interview-oriented.

## 1. Merge Strings Alternately
**Idea:** Walk both strings with two pointers and append available characters.
**Time:** O(n + m)  **Space:** O(n + m)

```java
class Solution {
    public String mergeAlternately(String word1, String word2) {
        StringBuilder sb = new StringBuilder();
        int i = 0, j = 0;
        while (i < word1.length() || j < word2.length()) {
            if (i < word1.length()) sb.append(word1.charAt(i++));
            if (j < word2.length()) sb.append(word2.charAt(j++));
        }
        return sb.toString();
    }
}
```

## 2. Greatest Common Divisor of Strings
**Idea:** Valid only if `str1 + str2 == str2 + str1`; answer length is `gcd(len1, len2)`.
**Time:** O(n + m)  **Space:** O(n + m)

```java
class Solution {
    public String gcdOfStrings(String str1, String str2) {
        if (!(str1 + str2).equals(str2 + str1)) return "";
        int len = gcd(str1.length(), str2.length());
        return str1.substring(0, len);
    }

    private int gcd(int a, int b) {
        while (b != 0) {
            int t = a % b;
            a = b;
            b = t;
        }
        return a;
    }
}
```

## 3. Kids With the Greatest Number of Candies
**Idea:** Find max, then test each child.
**Time:** O(n)  **Space:** O(n)

```java
class Solution {
    public List<Boolean> kidsWithCandies(int[] candies, int extraCandies) {
        int max = 0;
        for (int c : candies) max = Math.max(max, c);
        List<Boolean> ans = new ArrayList<>();
        for (int c : candies) ans.add(c + extraCandies >= max);
        return ans;
    }
}
```

## 4. Can Place Flowers
**Idea:** Greedily plant when left and right spots are empty.
**Time:** O(n)  **Space:** O(1)

```java
class Solution {
    public boolean canPlaceFlowers(int[] flowerbed, int n) {
        for (int i = 0; i < flowerbed.length && n > 0; i++) {
            if (flowerbed[i] == 0) {
                int left = (i == 0) ? 0 : flowerbed[i - 1];
                int right = (i == flowerbed.length - 1) ? 0 : flowerbed[i + 1];
                if (left == 0 && right == 0) {
                    flowerbed[i] = 1;
                    n--;
                }
            }
        }
        return n == 0;
    }
}
```

## 5. Reverse Vowels of a String
**Idea:** Two pointers moving inward, swapping vowels only.
**Time:** O(n)  **Space:** O(n)

```java
class Solution {
    public String reverseVowels(String s) {
        Set<Character> vowels = new HashSet<>(Arrays.asList('a','e','i','o','u','A','E','I','O','U'));
        char[] arr = s.toCharArray();
        int l = 0, r = arr.length - 1;
        while (l < r) {
            while (l < r && !vowels.contains(arr[l])) l++;
            while (l < r && !vowels.contains(arr[r])) r--;
            char tmp = arr[l]; arr[l] = arr[r]; arr[r] = tmp;
            l++; r--;
        }
        return new String(arr);
    }
}
```

## 6. Reverse Words in a String
**Idea:** Trim, split on whitespace, rebuild in reverse order.
**Time:** O(n)  **Space:** O(n)

```java
class Solution {
    public String reverseWords(String s) {
        String[] parts = s.trim().split("\\s+");
        StringBuilder sb = new StringBuilder();
        for (int i = parts.length - 1; i >= 0; i--) {
            sb.append(parts[i]);
            if (i > 0) sb.append(' ');
        }
        return sb.toString();
    }
}
```

## 7. Product of Array Except Self
**Idea:** Prefix products from left and suffix multiplier from right.
**Time:** O(n)  **Space:** O(1) extra (excluding output)

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

## 8. Increasing Triplet Subsequence
**Idea:** Track smallest and second smallest values seen so far.
**Time:** O(n)  **Space:** O(1)

```java
class Solution {
    public boolean increasingTriplet(int[] nums) {
        int first = Integer.MAX_VALUE, second = Integer.MAX_VALUE;
        for (int x : nums) {
            if (x <= first) first = x;
            else if (x <= second) second = x;
            else return true;
        }
        return false;
    }
}
```

## 9. String Compression
**Idea:** Use read/write pointers and write counts in place.
**Time:** O(n)  **Space:** O(1)

```java
class Solution {
    public int compress(char[] chars) {
        int write = 0, read = 0;
        while (read < chars.length) {
            char ch = chars[read];
            int start = read;
            while (read < chars.length && chars[read] == ch) read++;
            chars[write++] = ch;
            int count = read - start;
            if (count > 1) {
                for (char c : Integer.toString(count).toCharArray()) chars[write++] = c;
            }
        }
        return write;
    }
}
```

## 10. Move Zeroes
**Idea:** Compact non-zeroes to front, then fill remainder with zeroes.
**Time:** O(n)  **Space:** O(1)

```java
class Solution {
    public void moveZeroes(int[] nums) {
        int insert = 0;
        for (int x : nums) if (x != 0) nums[insert++] = x;
        while (insert < nums.length) nums[insert++] = 0;
    }
}
```

## 11. Is Subsequence
**Idea:** Advance pointer in `s` when matching chars in `t`.
**Time:** O(n)  **Space:** O(1)

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

## 12. Container With Most Water
**Idea:** Two pointers; move the shorter side.
**Time:** O(n)  **Space:** O(1)

```java
class Solution {
    public int maxArea(int[] height) {
        int l = 0, r = height.length - 1, ans = 0;
        while (l < r) {
            ans = Math.max(ans, Math.min(height[l], height[r]) * (r - l));
            if (height[l] < height[r]) l++;
            else r--;
        }
        return ans;
    }
}
```

## 13. Max Number of K-Sum Pairs
**Idea:** Count complements with a hash map.
**Time:** O(n)  **Space:** O(n)

```java
class Solution {
    public int maxOperations(int[] nums, int k) {
        Map<Integer, Integer> map = new HashMap<>();
        int ans = 0;
        for (int x : nums) {
            int need = k - x;
            if (map.getOrDefault(need, 0) > 0) {
                ans++;
                map.put(need, map.get(need) - 1);
            } else {
                map.put(x, map.getOrDefault(x, 0) + 1);
            }
        }
        return ans;
    }
}
```

## 14. Maximum Average Subarray I
**Idea:** Fixed-size sliding window sum.
**Time:** O(n)  **Space:** O(1)

```java
class Solution {
    public double findMaxAverage(int[] nums, int k) {
        long sum = 0;
        for (int i = 0; i < k; i++) sum += nums[i];
        long best = sum;
        for (int i = k; i < nums.length; i++) {
            sum += nums[i] - nums[i - k];
            best = Math.max(best, sum);
        }
        return best / (double) k;
    }
}
```

## 15. Maximum Number of Vowels in a Substring of Given Length
**Idea:** Sliding window over vowel count.
**Time:** O(n)  **Space:** O(1)

```java
class Solution {
    public int maxVowels(String s, int k) {
        int count = 0, ans = 0;
        for (int i = 0; i < s.length(); i++) {
            if (isVowel(s.charAt(i))) count++;
            if (i >= k && isVowel(s.charAt(i - k))) count--;
            if (i >= k - 1) ans = Math.max(ans, count);
        }
        return ans;
    }

    private boolean isVowel(char c) {
        return "aeiou".indexOf(c) >= 0;
    }
}
```

## 16. Max Consecutive Ones III
**Idea:** Maintain a window with at most `k` zeroes.
**Time:** O(n)  **Space:** O(1)

```java
class Solution {
    public int longestOnes(int[] nums, int k) {
        int left = 0, zeroes = 0, ans = 0;
        for (int right = 0; right < nums.length; right++) {
            if (nums[right] == 0) zeroes++;
            while (zeroes > k) {
                if (nums[left++] == 0) zeroes--;
            }
            ans = Math.max(ans, right - left + 1);
        }
        return ans;
    }
}
```

## 17. Longest Subarray of 1's After Deleting One Element
**Idea:** Window with at most one zero; answer is window size minus one deletion.
**Time:** O(n)  **Space:** O(1)

```java
class Solution {
    public int longestSubarray(int[] nums) {
        int left = 0, zeroes = 0, ans = 0;
        for (int right = 0; right < nums.length; right++) {
            if (nums[right] == 0) zeroes++;
            while (zeroes > 1) {
                if (nums[left++] == 0) zeroes--;
            }
            ans = Math.max(ans, right - left);
        }
        return ans;
    }
}
```

## 18. Find the Highest Altitude
**Idea:** Running prefix sum and track maximum.
**Time:** O(n)  **Space:** O(1)

```java
class Solution {
    public int largestAltitude(int[] gain) {
        int cur = 0, ans = 0;
        for (int g : gain) {
            cur += g;
            ans = Math.max(ans, cur);
        }
        return ans;
    }
}
```

## 19. Find Pivot Index
**Idea:** Left sum equals total minus left minus current.
**Time:** O(n)  **Space:** O(1)

```java
class Solution {
    public int pivotIndex(int[] nums) {
        int total = 0, left = 0;
        for (int x : nums) total += x;
        for (int i = 0; i < nums.length; i++) {
            if (left == total - left - nums[i]) return i;
            left += nums[i];
        }
        return -1;
    }
}
```

## 20. Find the Difference of Two Arrays
**Idea:** Deduplicate with sets, then collect unique elements.
**Time:** O(n + m)  **Space:** O(n + m)

```java
class Solution {
    public List<List<Integer>> findDifference(int[] nums1, int[] nums2) {
        Set<Integer> s1 = new HashSet<>(), s2 = new HashSet<>();
        for (int x : nums1) s1.add(x);
        for (int x : nums2) s2.add(x);
        List<Integer> a = new ArrayList<>(), b = new ArrayList<>();
        for (int x : s1) if (!s2.contains(x)) a.add(x);
        for (int x : s2) if (!s1.contains(x)) b.add(x);
        return Arrays.asList(a, b);
    }
}
```

## 21. Unique Number of Occurrences
**Idea:** Compare count map size to set-of-counts size.
**Time:** O(n)  **Space:** O(n)

```java
class Solution {
    public boolean uniqueOccurrences(int[] arr) {
        Map<Integer, Integer> freq = new HashMap<>();
        for (int x : arr) freq.put(x, freq.getOrDefault(x, 0) + 1);
        return new HashSet<>(freq.values()).size() == freq.size();
    }
}
```

## 22. Determine if Two Strings Are Close
**Idea:** Same character set and same multiset of frequencies.
**Time:** O(n log n)  **Space:** O(1)

```java
class Solution {
    public boolean closeStrings(String word1, String word2) {
        if (word1.length() != word2.length()) return false;
        int[] a = new int[26], b = new int[26];
        for (char c : word1.toCharArray()) a[c - 'a']++;
        for (char c : word2.toCharArray()) b[c - 'a']++;
        for (int i = 0; i < 26; i++) {
            if ((a[i] == 0) != (b[i] == 0)) return false;
        }
        Arrays.sort(a);
        Arrays.sort(b);
        return Arrays.equals(a, b);
    }
}
```

## 23. Equal Row and Column Pairs
**Idea:** Encode each row, count it, then encode columns and match.
**Time:** O(n^2)  **Space:** O(n^2)

```java
class Solution {
    public int equalPairs(int[][] grid) {
        int n = grid.length;
        Map<String, Integer> map = new HashMap<>();
        for (int[] row : grid) {
            String key = Arrays.toString(row);
            map.put(key, map.getOrDefault(key, 0) + 1);
        }
        int ans = 0;
        for (int c = 0; c < n; c++) {
            int[] col = new int[n];
            for (int r = 0; r < n; r++) col[r] = grid[r][c];
            ans += map.getOrDefault(Arrays.toString(col), 0);
        }
        return ans;
    }
}
```

## 24. Removing Stars From a String
**Idea:** Use a stack-like builder and delete previous char on `*`.
**Time:** O(n)  **Space:** O(n)

```java
class Solution {
    public String removeStars(String s) {
        StringBuilder sb = new StringBuilder();
        for (char c : s.toCharArray()) {
            if (c == '*') sb.deleteCharAt(sb.length() - 1);
            else sb.append(c);
        }
        return sb.toString();
    }
}
```

## 25. Asteroid Collision
**Idea:** Maintain surviving asteroids in a stack.
**Time:** O(n)  **Space:** O(n)

```java
class Solution {
    public int[] asteroidCollision(int[] asteroids) {
        Deque<Integer> st = new ArrayDeque<>();
        for (int a : asteroids) {
            boolean alive = true;
            while (alive && a < 0 && !st.isEmpty() && st.peek() > 0) {
                if (st.peek() < -a) st.pop();
                else if (st.peek() == -a) { st.pop(); alive = false; }
                else alive = false;
            }
            if (alive) st.push(a);
        }
        int[] ans = new int[st.size()];
        for (int i = ans.length - 1; i >= 0; i--) ans[i] = st.pop();
        return ans;
    }
}
```

## 26. Decode String
**Idea:** Stack counts and previous builders at each `[`.
**Time:** O(n * k) in expanded output size  **Space:** O(n)

```java
class Solution {
    public String decodeString(String s) {
        Deque<Integer> counts = new ArrayDeque<>();
        Deque<StringBuilder> stack = new ArrayDeque<>();
        StringBuilder cur = new StringBuilder();
        int num = 0;
        for (char c : s.toCharArray()) {
            if (Character.isDigit(c)) num = num * 10 + (c - '0');
            else if (c == '[') {
                counts.push(num);
                stack.push(cur);
                cur = new StringBuilder();
                num = 0;
            } else if (c == ']') {
                int repeat = counts.pop();
                StringBuilder prev = stack.pop();
                for (int i = 0; i < repeat; i++) prev.append(cur);
                cur = prev;
            } else cur.append(c);
        }
        return cur.toString();
    }
}
```

## 27. Number of Recent Calls
**Idea:** Queue timestamps still within 3000 ms window.
**Time:** O(1) amortized  **Space:** O(n)

```java
class RecentCounter {
    private final Queue<Integer> q = new ArrayDeque<>();

    public RecentCounter() {}

    public int ping(int t) {
        q.offer(t);
        while (q.peek() < t - 3000) q.poll();
        return q.size();
    }
}
```

## 28. Dota2 Senate
**Idea:** Simulate turns with two queues of indices.
**Time:** O(n)  **Space:** O(n)

```java
class Solution {
    public String predictPartyVictory(String senate) {
        Queue<Integer> r = new ArrayDeque<>(), d = new ArrayDeque<>();
        int n = senate.length();
        for (int i = 0; i < n; i++) {
            if (senate.charAt(i) == 'R') r.offer(i);
            else d.offer(i);
        }
        while (!r.isEmpty() && !d.isEmpty()) {
            int ri = r.poll(), di = d.poll();
            if (ri < di) r.offer(ri + n);
            else d.offer(di + n);
        }
        return r.isEmpty() ? "Dire" : "Radiant";
    }
}
```

## 29. Delete the Middle Node of a Linked List
**Idea:** Find middle with slow/fast and remove it.
**Time:** O(n)  **Space:** O(1)

```java
class Solution {
    public ListNode deleteMiddle(ListNode head) {
        if (head == null || head.next == null) return null;
        ListNode slow = head, fast = head, prev = null;
        while (fast != null && fast.next != null) {
            prev = slow;
            slow = slow.next;
            fast = fast.next.next;
        }
        prev.next = slow.next;
        return head;
    }
}
```

## 30. Odd Even Linked List
**Idea:** Stitch odd nodes together, then append even list.
**Time:** O(n)  **Space:** O(1)

```java
class Solution {
    public ListNode oddEvenList(ListNode head) {
        if (head == null) return null;
        ListNode odd = head, even = head.next, evenHead = even;
        while (even != null && even.next != null) {
            odd.next = even.next;
            odd = odd.next;
            even.next = odd.next;
            even = even.next;
        }
        odd.next = evenHead;
        return head;
    }
}
```

## 31. Reverse Linked List
**Idea:** Iterative pointer reversal.
**Time:** O(n)  **Space:** O(1)

```java
class Solution {
    public ListNode reverseList(ListNode head) {
        ListNode prev = null, cur = head;
        while (cur != null) {
            ListNode next = cur.next;
            cur.next = prev;
            prev = cur;
            cur = next;
        }
        return prev;
    }
}
```

## 32. Maximum Twin Sum of a Linked List
**Idea:** Find middle, reverse second half, compare pairs.
**Time:** O(n)  **Space:** O(1)

```java
class Solution {
    public int pairSum(ListNode head) {
        ListNode slow = head, fast = head;
        while (fast != null && fast.next != null) {
            slow = slow.next;
            fast = fast.next.next;
        }
        ListNode prev = null;
        while (slow != null) {
            ListNode next = slow.next;
            slow.next = prev;
            prev = slow;
            slow = next;
        }
        int ans = 0;
        while (prev != null) {
            ans = Math.max(ans, head.val + prev.val);
            head = head.next;
            prev = prev.next;
        }
        return ans;
    }
}
```

## 33. Maximum Depth of Binary Tree
**Idea:** DFS height = 1 + max(left, right).
**Time:** O(n)  **Space:** O(h)

```java
class Solution {
    public int maxDepth(TreeNode root) {
        if (root == null) return 0;
        return 1 + Math.max(maxDepth(root.left), maxDepth(root.right));
    }
}
```

## 34. Leaf-Similar Trees
**Idea:** Collect leaf sequences and compare.
**Time:** O(n + m)  **Space:** O(n + m)

```java
class Solution {
    public boolean leafSimilar(TreeNode root1, TreeNode root2) {
        List<Integer> a = new ArrayList<>(), b = new ArrayList<>();
        dfs(root1, a);
        dfs(root2, b);
        return a.equals(b);
    }

    private void dfs(TreeNode node, List<Integer> leaves) {
        if (node == null) return;
        if (node.left == null && node.right == null) {
            leaves.add(node.val);
            return;
        }
        dfs(node.left, leaves);
        dfs(node.right, leaves);
    }
}
```

## 35. Count Good Nodes in Binary Tree
**Idea:** DFS with max value seen on path.
**Time:** O(n)  **Space:** O(h)

```java
class Solution {
    public int goodNodes(TreeNode root) {
        return dfs(root, Integer.MIN_VALUE);
    }

    private int dfs(TreeNode node, int mx) {
        if (node == null) return 0;
        int good = node.val >= mx ? 1 : 0;
        mx = Math.max(mx, node.val);
        return good + dfs(node.left, mx) + dfs(node.right, mx);
    }
}
```

## 36. Path Sum III
**Idea:** Prefix sum counts on root-to-node path.
**Time:** O(n)  **Space:** O(n)

```java
class Solution {
    public int pathSum(TreeNode root, int targetSum) {
        Map<Long, Integer> map = new HashMap<>();
        map.put(0L, 1);
        return dfs(root, 0L, targetSum, map);
    }

    private int dfs(TreeNode node, long sum, int target, Map<Long, Integer> map) {
        if (node == null) return 0;
        sum += node.val;
        int ans = map.getOrDefault(sum - target, 0);
        map.put(sum, map.getOrDefault(sum, 0) + 1);
        ans += dfs(node.left, sum, target, map);
        ans += dfs(node.right, sum, target, map);
        map.put(sum, map.get(sum) - 1);
        return ans;
    }
}
```

## 37. Longest ZigZag Path in a Binary Tree
**Idea:** DFS keeping current direction and length.
**Time:** O(n)  **Space:** O(h)

```java
class Solution {
    private int ans = 0;

    public int longestZigZag(TreeNode root) {
        dfs(root, true, 0);
        dfs(root, false, 0);
        return ans;
    }

    private void dfs(TreeNode node, boolean leftMove, int len) {
        if (node == null) return;
        ans = Math.max(ans, len);
        if (leftMove) {
            dfs(node.left, false, len + 1);
            dfs(node.right, true, 1);
        } else {
            dfs(node.right, true, len + 1);
            dfs(node.left, false, 1);
        }
    }
}
```

## 38. Lowest Common Ancestor of a Binary Tree
**Idea:** If targets split across subtrees, current node is LCA.
**Time:** O(n)  **Space:** O(h)

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

## 39. Binary Tree Right Side View
**Idea:** BFS by levels; keep last node of each level.
**Time:** O(n)  **Space:** O(n)

```java
class Solution {
    public List<Integer> rightSideView(TreeNode root) {
        List<Integer> ans = new ArrayList<>();
        if (root == null) return ans;
        Queue<TreeNode> q = new ArrayDeque<>();
        q.offer(root);
        while (!q.isEmpty()) {
            int size = q.size();
            for (int i = 0; i < size; i++) {
                TreeNode node = q.poll();
                if (i == size - 1) ans.add(node.val);
                if (node.left != null) q.offer(node.left);
                if (node.right != null) q.offer(node.right);
            }
        }
        return ans;
    }
}
```

## 40. Maximum Level Sum of a Binary Tree
**Idea:** BFS and track level sums.
**Time:** O(n)  **Space:** O(n)

```java
class Solution {
    public int maxLevelSum(TreeNode root) {
        Queue<TreeNode> q = new ArrayDeque<>();
        q.offer(root);
        int level = 1, bestLevel = 1;
        long bestSum = Long.MIN_VALUE;
        while (!q.isEmpty()) {
            int size = q.size();
            long sum = 0;
            for (int i = 0; i < size; i++) {
                TreeNode node = q.poll();
                sum += node.val;
                if (node.left != null) q.offer(node.left);
                if (node.right != null) q.offer(node.right);
            }
            if (sum > bestSum) {
                bestSum = sum;
                bestLevel = level;
            }
            level++;
        }
        return bestLevel;
    }
}
```

## 41. Search in a Binary Search Tree
**Idea:** Walk left or right by BST property.
**Time:** O(h)  **Space:** O(1)

```java
class Solution {
    public TreeNode searchBST(TreeNode root, int val) {
        while (root != null && root.val != val) {
            root = val < root.val ? root.left : root.right;
        }
        return root;
    }
}
```

## 42. Delete Node in a BST
**Idea:** Standard BST deletion with inorder successor.
**Time:** O(h)  **Space:** O(h)

```java
class Solution {
    public TreeNode deleteNode(TreeNode root, int key) {
        if (root == null) return null;
        if (key < root.val) root.left = deleteNode(root.left, key);
        else if (key > root.val) root.right = deleteNode(root.right, key);
        else {
            if (root.left == null) return root.right;
            if (root.right == null) return root.left;
            TreeNode succ = root.right;
            while (succ.left != null) succ = succ.left;
            root.val = succ.val;
            root.right = deleteNode(root.right, succ.val);
        }
        return root;
    }
}
```

## 43. Keys and Rooms
**Idea:** DFS/BFS from room 0 and see if all rooms become visited.
**Time:** O(V + E)  **Space:** O(V)

```java
class Solution {
    public boolean canVisitAllRooms(List<List<Integer>> rooms) {
        boolean[] seen = new boolean[rooms.size()];
        dfs(0, rooms, seen);
        for (boolean b : seen) if (!b) return false;
        return true;
    }

    private void dfs(int room, List<List<Integer>> rooms, boolean[] seen) {
        if (seen[room]) return;
        seen[room] = true;
        for (int next : rooms.get(room)) dfs(next, rooms, seen);
    }
}
```

## 44. Number of Provinces
**Idea:** Count connected components in adjacency matrix.
**Time:** O(n^2)  **Space:** O(n)

```java
class Solution {
    public int findCircleNum(int[][] isConnected) {
        int n = isConnected.length, ans = 0;
        boolean[] seen = new boolean[n];
        for (int i = 0; i < n; i++) {
            if (!seen[i]) {
                ans++;
                dfs(isConnected, seen, i);
            }
        }
        return ans;
    }

    private void dfs(int[][] g, boolean[] seen, int u) {
        seen[u] = true;
        for (int v = 0; v < g.length; v++) {
            if (g[u][v] == 1 && !seen[v]) dfs(g, seen, v);
        }
    }
}
```

## 45. Reorder Routes to Make All Paths Lead to the City Zero
**Idea:** Build undirected graph and mark original edge directions.
**Time:** O(n)  **Space:** O(n)

```java
class Solution {
    public int minReorder(int n, int[][] connections) {
        List<int[]>[] g = new ArrayList[n];
        for (int i = 0; i < n; i++) g[i] = new ArrayList<>();
        for (int[] e : connections) {
            g[e[0]].add(new int[]{e[1], 1});
            g[e[1]].add(new int[]{e[0], 0});
        }
        return dfs(0, -1, g);
    }

    private int dfs(int u, int parent, List<int[]>[] g) {
        int changes = 0;
        for (int[] nxt : g[u]) {
            int v = nxt[0], cost = nxt[1];
            if (v == parent) continue;
            changes += cost + dfs(v, u, g);
        }
        return changes;
    }
}
```

## 46. Evaluate Division
**Idea:** Weighted graph; DFS from numerator to denominator.
**Time:** O(E + Q * (V + E)) worst-case  **Space:** O(V + E)

```java
class Solution {
    public double[] calcEquation(List<List<String>> equations, double[] values, List<List<String>> queries) {
        Map<String, List<Pair>> g = new HashMap<>();
        for (int i = 0; i < equations.size(); i++) {
            String a = equations.get(i).get(0), b = equations.get(i).get(1);
            g.computeIfAbsent(a, k -> new ArrayList<>()).add(new Pair(b, values[i]));
            g.computeIfAbsent(b, k -> new ArrayList<>()).add(new Pair(a, 1.0 / values[i]));
        }
        double[] ans = new double[queries.size()];
        for (int i = 0; i < queries.size(); i++) {
            String src = queries.get(i).get(0), dst = queries.get(i).get(1);
            if (!g.containsKey(src) || !g.containsKey(dst)) ans[i] = -1.0;
            else if (src.equals(dst)) ans[i] = 1.0;
            else ans[i] = dfs(src, dst, g, new HashSet<>());
        }
        return ans;
    }

    private double dfs(String cur, String target, Map<String, List<Pair>> g, Set<String> seen) {
        if (cur.equals(target)) return 1.0;
        seen.add(cur);
        for (Pair nei : g.get(cur)) {
            if (seen.contains(nei.node)) continue;
            double sub = dfs(nei.node, target, g, seen);
            if (sub != -1.0) return nei.weight * sub;
        }
        return -1.0;
    }

    static class Pair {
        String node;
        double weight;
        Pair(String n, double w) { node = n; weight = w; }
    }
}
```

## 47. Nearest Exit from Entrance in Maze
**Idea:** BFS shortest path from entrance.
**Time:** O(mn)  **Space:** O(mn)

```java
class Solution {
    public int nearestExit(char[][] maze, int[] entrance) {
        int m = maze.length, n = maze[0].length;
        Queue<int[]> q = new ArrayDeque<>();
        q.offer(new int[]{entrance[0], entrance[1], 0});
        maze[entrance[0]][entrance[1]] = '+';
        int[][] dirs = {{1,0},{-1,0},{0,1},{0,-1}};
        while (!q.isEmpty()) {
            int[] cur = q.poll();
            int r = cur[0], c = cur[1], d = cur[2];
            if ((r != entrance[0] || c != entrance[1]) && (r == 0 || c == 0 || r == m - 1 || c == n - 1)) return d;
            for (int[] dir : dirs) {
                int nr = r + dir[0], nc = c + dir[1];
                if (nr >= 0 && nr < m && nc >= 0 && nc < n && maze[nr][nc] == '.') {
                    maze[nr][nc] = '+';
                    q.offer(new int[]{nr, nc, d + 1});
                }
            }
        }
        return -1;
    }
}
```

## 48. Rotting Oranges
**Idea:** Multi-source BFS from all rotten oranges.
**Time:** O(mn)  **Space:** O(mn)

```java
class Solution {
    public int orangesRotting(int[][] grid) {
        int m = grid.length, n = grid[0].length, fresh = 0, minutes = 0;
        Queue<int[]> q = new ArrayDeque<>();
        for (int i = 0; i < m; i++) {
            for (int j = 0; j < n; j++) {
                if (grid[i][j] == 2) q.offer(new int[]{i, j});
                else if (grid[i][j] == 1) fresh++;
            }
        }
        int[][] dirs = {{1,0},{-1,0},{0,1},{0,-1}};
        while (!q.isEmpty() && fresh > 0) {
            int size = q.size();
            minutes++;
            for (int i = 0; i < size; i++) {
                int[] cur = q.poll();
                for (int[] dir : dirs) {
                    int nr = cur[0] + dir[0], nc = cur[1] + dir[1];
                    if (nr >= 0 && nr < m && nc >= 0 && nc < n && grid[nr][nc] == 1) {
                        grid[nr][nc] = 2;
                        fresh--;
                        q.offer(new int[]{nr, nc});
                    }
                }
            }
        }
        return fresh == 0 ? minutes : -1;
    }
}
```

## 49. Kth Largest Element in an Array
**Idea:** Keep a min-heap of size `k`.
**Time:** O(n log k)  **Space:** O(k)

```java
class Solution {
    public int findKthLargest(int[] nums, int k) {
        PriorityQueue<Integer> pq = new PriorityQueue<>();
        for (int x : nums) {
            pq.offer(x);
            if (pq.size() > k) pq.poll();
        }
        return pq.peek();
    }
}
```

## 50. Smallest Number in Infinite Set
**Idea:** Track numbers added back using a min-heap and set, plus next fresh number.
**Time:** O(log n) per op  **Space:** O(n)

```java
class SmallestInfiniteSet {
    private int next = 1;
    private final PriorityQueue<Integer> pq = new PriorityQueue<>();
    private final Set<Integer> set = new HashSet<>();

    public SmallestInfiniteSet() {}

    public int popSmallest() {
        if (!pq.isEmpty()) {
            int x = pq.poll();
            set.remove(x);
            return x;
        }
        return next++;
    }

    public void addBack(int num) {
        if (num < next && set.add(num)) pq.offer(num);
    }
}
```

## 51. Maximum Subsequence Score
**Idea:** Sort by `nums2` descending; keep best `k` `nums1` values with min-heap.
**Time:** O(n log n)  **Space:** O(n)

```java
class Solution {
    public long maxScore(int[] nums1, int[] nums2, int k) {
        int n = nums1.length;
        int[][] pairs = new int[n][2];
        for (int i = 0; i < n; i++) {
            pairs[i][0] = nums2[i];
            pairs[i][1] = nums1[i];
        }
        Arrays.sort(pairs, (a, b) -> Integer.compare(b[0], a[0]));
        PriorityQueue<Integer> pq = new PriorityQueue<>();
        long sum = 0, ans = 0;
        for (int[] p : pairs) {
            pq.offer(p[1]);
            sum += p[1];
            if (pq.size() > k) sum -= pq.poll();
            if (pq.size() == k) ans = Math.max(ans, sum * p[0]);
        }
        return ans;
    }
}
```

## 52. Total Cost to Hire K Workers
**Idea:** Two-side candidate windows with one min-heap.
**Time:** O((k + candidates) log candidates)  **Space:** O(candidates)

```java
class Solution {
    public long totalCost(int[] costs, int k, int candidates) {
        PriorityQueue<int[]> pq = new PriorityQueue<>((a, b) -> {
            if (a[0] != b[0]) return Integer.compare(a[0], b[0]);
            return Integer.compare(a[1], b[1]);
        });
        int l = 0, r = costs.length - 1;
        for (int i = 0; i < candidates && l <= r; i++) pq.offer(new int[]{costs[l], 0, l++});
        for (int i = 0; i < candidates && l <= r; i++) pq.offer(new int[]{costs[r], 1, r--});
        long ans = 0;
        while (k-- > 0) {
            int[] cur = pq.poll();
            ans += cur[0];
            if (l <= r) {
                if (cur[1] == 0) pq.offer(new int[]{costs[l], 0, l++});
                else pq.offer(new int[]{costs[r], 1, r--});
            }
        }
        return ans;
    }
}
```

## 53. Guess Number Higher or Lower
**Idea:** Classic binary search on answer space.
**Time:** O(log n)  **Space:** O(1)

```java
public class Solution extends GuessGame {
    public int guessNumber(int n) {
        int l = 1, r = n;
        while (l <= r) {
            int mid = l + (r - l) / 2;
            int g = guess(mid);
            if (g == 0) return mid;
            if (g < 0) r = mid - 1;
            else l = mid + 1;
        }
        return -1;
    }
}
```

## 54. Successful Pairs of Spells and Potions
**Idea:** Sort potions and binary-search first successful one for each spell.
**Time:** O(m log m + n log m)  **Space:** O(m) depending on sort implementation

```java
class Solution {
    public int[] successfulPairs(int[] spells, int[] potions, long success) {
        Arrays.sort(potions);
        int[] ans = new int[spells.length];
        int m = potions.length;
        for (int i = 0; i < spells.length; i++) {
            int l = 0, r = m - 1, idx = m;
            while (l <= r) {
                int mid = l + (r - l) / 2;
                if ((long) spells[i] * potions[mid] >= success) {
                    idx = mid;
                    r = mid - 1;
                } else l = mid + 1;
            }
            ans[i] = m - idx;
        }
        return ans;
    }
}
```

## 55. Find Peak Element
**Idea:** Binary search using slope direction.
**Time:** O(log n)  **Space:** O(1)

```java
class Solution {
    public int findPeakElement(int[] nums) {
        int l = 0, r = nums.length - 1;
        while (l < r) {
            int mid = l + (r - l) / 2;
            if (nums[mid] > nums[mid + 1]) r = mid;
            else l = mid + 1;
        }
        return l;
    }
}
```

## 56. Koko Eating Bananas
**Idea:** Binary-search eating speed; check hours needed.
**Time:** O(n log maxPile)  **Space:** O(1)

```java
class Solution {
    public int minEatingSpeed(int[] piles, int h) {
        int l = 1, r = 0;
        for (int p : piles) r = Math.max(r, p);
        while (l < r) {
            int mid = l + (r - l) / 2;
            if (canFinish(piles, h, mid)) r = mid;
            else l = mid + 1;
        }
        return l;
    }

    private boolean canFinish(int[] piles, int h, int k) {
        long hours = 0;
        for (int p : piles) hours += (p + k - 1) / k;
        return hours <= h;
    }
}
```

## 57. Letter Combinations of a Phone Number
**Idea:** Backtracking over digit-to-letter mapping.
**Time:** O(4^n * n)  **Space:** O(n)

```java
class Solution {
    private static final String[] MAP = {"", "", "abc", "def", "ghi", "jkl", "mno", "pqrs", "tuv", "wxyz"};

    public List<String> letterCombinations(String digits) {
        List<String> ans = new ArrayList<>();
        if (digits.isEmpty()) return ans;
        backtrack(digits, 0, new StringBuilder(), ans);
        return ans;
    }

    private void backtrack(String digits, int idx, StringBuilder path, List<String> ans) {
        if (idx == digits.length()) {
            ans.add(path.toString());
            return;
        }
        String letters = MAP[digits.charAt(idx) - '0'];
        for (char c : letters.toCharArray()) {
            path.append(c);
            backtrack(digits, idx + 1, path, ans);
            path.deleteCharAt(path.length() - 1);
        }
    }
}
```

## 58. Combination Sum III
**Idea:** Backtrack choosing numbers 1..9 without reuse.
**Time:** O(C(9, k))  **Space:** O(k)

```java
class Solution {
    public List<List<Integer>> combinationSum3(int k, int n) {
        List<List<Integer>> ans = new ArrayList<>();
        backtrack(1, k, n, new ArrayList<>(), ans);
        return ans;
    }

    private void backtrack(int start, int k, int remain, List<Integer> path, List<List<Integer>> ans) {
        if (path.size() == k) {
            if (remain == 0) ans.add(new ArrayList<>(path));
            return;
        }
        for (int i = start; i <= 9; i++) {
            if (i > remain) break;
            path.add(i);
            backtrack(i + 1, k, remain - i, path, ans);
            path.remove(path.size() - 1);
        }
    }
}
```

## 59. N-th Tribonacci Number
**Idea:** Bottom-up DP with rolling variables.
**Time:** O(n)  **Space:** O(1)

```java
class Solution {
    public int tribonacci(int n) {
        if (n == 0) return 0;
        if (n <= 2) return 1;
        int a = 0, b = 1, c = 1;
        for (int i = 3; i <= n; i++) {
            int d = a + b + c;
            a = b;
            b = c;
            c = d;
        }
        return c;
    }
}
```

## 60. Min Cost Climbing Stairs
**Idea:** DP from the end with rolling states.
**Time:** O(n)  **Space:** O(1)

```java
class Solution {
    public int minCostClimbingStairs(int[] cost) {
        int a = 0, b = 0;
        for (int i = cost.length - 1; i >= 0; i--) {
            int cur = cost[i] + Math.min(a, b);
            b = a;
            a = cur;
        }
        return Math.min(a, b);
    }
}
```

## 61. House Robber
**Idea:** At each house, choose rob or skip.
**Time:** O(n)  **Space:** O(1)

```java
class Solution {
    public int rob(int[] nums) {
        int prev2 = 0, prev1 = 0;
        for (int x : nums) {
            int cur = Math.max(prev1, prev2 + x);
            prev2 = prev1;
            prev1 = cur;
        }
        return prev1;
    }
}
```

## 62. Domino and Tromino Tiling
**Idea:** Use standard recurrence `dp[i] = 2*dp[i-1] + dp[i-3]`.
**Time:** O(n)  **Space:** O(n)

```java
class Solution {
    public int numTilings(int n) {
        long mod = 1_000_000_007L;
        if (n <= 2) return n;
        long[] dp = new long[Math.max(4, n + 1)];
        dp[0] = 1; dp[1] = 1; dp[2] = 2; dp[3] = 5;
        for (int i = 4; i <= n; i++) dp[i] = (2 * dp[i - 1] + dp[i - 3]) % mod;
        return (int) dp[n];
    }
}
```

## 63. Unique Paths
**Idea:** Grid DP where each cell = top + left.
**Time:** O(mn)  **Space:** O(n)

```java
class Solution {
    public int uniquePaths(int m, int n) {
        int[] dp = new int[n];
        Arrays.fill(dp, 1);
        for (int i = 1; i < m; i++) {
            for (int j = 1; j < n; j++) dp[j] += dp[j - 1];
        }
        return dp[n - 1];
    }
}
```

## 64. Longest Common Subsequence
**Idea:** Classic 2D DP.
**Time:** O(mn)  **Space:** O(mn)

```java
class Solution {
    public int longestCommonSubsequence(String text1, String text2) {
        int m = text1.length(), n = text2.length();
        int[][] dp = new int[m + 1][n + 1];
        for (int i = 1; i <= m; i++) {
            for (int j = 1; j <= n; j++) {
                if (text1.charAt(i - 1) == text2.charAt(j - 1)) dp[i][j] = 1 + dp[i - 1][j - 1];
                else dp[i][j] = Math.max(dp[i - 1][j], dp[i][j - 1]);
            }
        }
        return dp[m][n];
    }
}
```

## 65. Best Time to Buy and Sell Stock with Transaction Fee
**Idea:** DP with `hold` and `cash` states.
**Time:** O(n)  **Space:** O(1)

```java
class Solution {
    public int maxProfit(int[] prices, int fee) {
        int hold = -prices[0], cash = 0;
        for (int i = 1; i < prices.length; i++) {
            int prevCash = cash;
            cash = Math.max(cash, hold + prices[i] - fee);
            hold = Math.max(hold, prevCash - prices[i]);
        }
        return cash;
    }
}
```

## 66. Edit Distance
**Idea:** DP on prefixes with insert/delete/replace transitions.
**Time:** O(mn)  **Space:** O(mn)

```java
class Solution {
    public int minDistance(String word1, String word2) {
        int m = word1.length(), n = word2.length();
        int[][] dp = new int[m + 1][n + 1];
        for (int i = 0; i <= m; i++) dp[i][0] = i;
        for (int j = 0; j <= n; j++) dp[0][j] = j;
        for (int i = 1; i <= m; i++) {
            for (int j = 1; j <= n; j++) {
                if (word1.charAt(i - 1) == word2.charAt(j - 1)) dp[i][j] = dp[i - 1][j - 1];
                else dp[i][j] = 1 + Math.min(dp[i - 1][j - 1], Math.min(dp[i - 1][j], dp[i][j - 1]));
            }
        }
        return dp[m][n];
    }
}
```

## 67. Counting Bits
**Idea:** `bits[i] = bits[i >> 1] + (i & 1)`.
**Time:** O(n)  **Space:** O(n)

```java
class Solution {
    public int[] countBits(int n) {
        int[] ans = new int[n + 1];
        for (int i = 1; i <= n; i++) ans[i] = ans[i >> 1] + (i & 1);
        return ans;
    }
}
```

## 68. Single Number
**Idea:** XOR cancels paired elements.
**Time:** O(n)  **Space:** O(1)

```java
class Solution {
    public int singleNumber(int[] nums) {
        int ans = 0;
        for (int x : nums) ans ^= x;
        return ans;
    }
}
```

## 69. Minimum Flips to Make a OR b Equal to c
**Idea:** Check each bit independently.
**Time:** O(1) for fixed-width ints  **Space:** O(1)

```java
class Solution {
    public int minFlips(int a, int b, int c) {
        int ans = 0;
        while (a > 0 || b > 0 || c > 0) {
            int x = a & 1, y = b & 1, z = c & 1;
            if ((x | y) != z) {
                if (z == 1) ans += 1;
                else ans += x + y;
            }
            a >>= 1; b >>= 1; c >>= 1;
        }
        return ans;
    }
}
```

## 70. Implement Trie (Prefix Tree)
**Idea:** Standard trie with 26 children.
**Time:** O(m) per operation  **Space:** O(total chars)

```java
class Trie {
    static class Node {
        Node[] next = new Node[26];
        boolean end;
    }

    private final Node root = new Node();

    public Trie() {}

    public void insert(String word) {
        Node cur = root;
        for (char c : word.toCharArray()) {
            int idx = c - 'a';
            if (cur.next[idx] == null) cur.next[idx] = new Node();
            cur = cur.next[idx];
        }
        cur.end = true;
    }

    public boolean search(String word) {
        Node node = walk(word);
        return node != null && node.end;
    }

    public boolean startsWith(String prefix) {
        return walk(prefix) != null;
    }

    private Node walk(String s) {
        Node cur = root;
        for (char c : s.toCharArray()) {
            cur = cur.next[c - 'a'];
            if (cur == null) return null;
        }
        return cur;
    }
}
```

## 71. Search Suggestions System
**Idea:** Sort products; binary search lower bound for each prefix.
**Time:** O(n log n + m log n)  **Space:** O(1) extra ignoring output

```java
class Solution {
    public List<List<String>> suggestedProducts(String[] products, String searchWord) {
        Arrays.sort(products);
        List<List<String>> ans = new ArrayList<>();
        String prefix = "";
        int start = 0;
        for (char ch : searchWord.toCharArray()) {
            prefix += ch;
            start = lowerBound(products, prefix, start);
            List<String> list = new ArrayList<>();
            for (int i = start; i < Math.min(start + 3, products.length); i++) {
                if (products[i].startsWith(prefix)) list.add(products[i]);
                else break;
            }
            ans.add(list);
        }
        return ans;
    }

    private int lowerBound(String[] arr, String target, int lo) {
        int hi = arr.length;
        while (lo < hi) {
            int mid = lo + (hi - lo) / 2;
            if (arr[mid].compareTo(target) < 0) lo = mid + 1;
            else hi = mid;
        }
        return lo;
    }
}
```

## 72. Non-overlapping Intervals
**Idea:** Sort by end time and greedily keep intervals that end earliest.
**Time:** O(n log n)  **Space:** O(log n) to O(n) depending on sort

```java
class Solution {
    public int eraseOverlapIntervals(int[][] intervals) {
        Arrays.sort(intervals, Comparator.comparingInt(a -> a[1]));
        int ans = 0, end = Integer.MIN_VALUE;
        for (int[] in : intervals) {
            if (in[0] >= end) end = in[1];
            else ans++;
        }
        return ans;
    }
}
```

## 73. Minimum Number of Arrows to Burst Balloons
**Idea:** Sort by end coordinate and greedily shoot at current end.
**Time:** O(n log n)  **Space:** O(log n) to O(n) depending on sort

```java
class Solution {
    public int findMinArrowShots(int[][] points) {
        Arrays.sort(points, (a, b) -> Long.compare((long) a[1], (long) b[1]));
        int arrows = 0;
        long end = Long.MIN_VALUE;
        for (int[] p : points) {
            if (arrows == 0 || p[0] > end) {
                arrows++;
                end = p[1];
            }
        }
        return arrows;
    }
}
```

## 74. Daily Temperatures
**Idea:** Monotonic decreasing stack of unresolved indices.
**Time:** O(n)  **Space:** O(n)

```java
class Solution {
    public int[] dailyTemperatures(int[] temperatures) {
        int n = temperatures.length;
        int[] ans = new int[n];
        Deque<Integer> st = new ArrayDeque<>();
        for (int i = 0; i < n; i++) {
            while (!st.isEmpty() && temperatures[i] > temperatures[st.peek()]) {
                int idx = st.pop();
                ans[idx] = i - idx;
            }
            st.push(i);
        }
        return ans;
    }
}
```

## 75. Online Stock Span
**Idea:** Monotonic stack storing `{price, span}` pairs.
**Time:** O(1) amortized per query  **Space:** O(n)

```java
class StockSpanner {
    private final Deque<int[]> st = new ArrayDeque<>();

    public StockSpanner() {}

    public int next(int price) {
        int span = 1;
        while (!st.isEmpty() && st.peek()[0] <= price) {
            span += st.pop()[1];
        }
        st.push(new int[]{price, span});
        return span;
    }
}
```
