## Notes

A tree is a graph with:

- No cycles
- Exactly one path between any two nodes
- N nodes and N-1 edges

**Terminology:**

- Height = longest path from root to leaf
- Depth = distance from root
- **Preorder**: Root → Left → Right; Use when root decision comes first.
- **Inorder**: Left → Root → Right; Use mostly in BST problems.
- **Postorder**: Left → Right → Root; Use when child information is needed before parent.
- **Binary Search Trees**: Left < Root < Right (Inorder traversal gives sorted order)

Almost every tree problem can be solved by asking:

"What information should each node return to its parent?"

This single idea solves most Medium/Hard tree problems.

## 0a. Height of a tree
```java
class Solution{
    int height(TreeNode root) {

    if(root == null)
        return 0;

    int left = height(root.left);
    int right = height(root.right);

    return 1 + Math.max(left, right);
}
}
```
## 0b. Diameter of a tree

**Diameter**: Longest path between any two nodes

```java
class Solution {
    int diameter = 0;
    public int diameterOfBinaryTree(TreeNode root) {
        if(root == null) return 0;
        computeHeight(root);
        return diameter;
    }

    private int computeHeight(TreeNode node){
        if(node == null) return 0;

        int left = computeHeight(node.left);
        int right = computeHeight(node.right);

        diameter = Math.max(diameter, left+right);

        return 1+Math.max(left, right);
    }
}
```
## 0c. Validate BST
```java
class Solution{
    boolean validate(TreeNode node, long min, long max) {

    if(node == null)
        return true;

    if(node.val <= min || node.val >= max)
        return false;

    return validate(node.left, min, node.val) && validate(node.right, node.val, max);
    }
}
```
## 1. Breadth First Search (Level Order) traversal
```java
class Solution {
    public List<List<Integer>> levelOrder(TreeNode root) {
        List<List<Integer>> res = new ArrayList();
        if(root == null) return res;

        Queue<TreeNode> q = new LinkedList();
        q.offer(root);

        while(!q.isEmpty()){
            int size = q.size();
            List<Integer> level = new ArrayList();
            
            for(int i = 0; i<size; i++){
                TreeNode node = q.poll();
                level.add(node.val);
                if(node.left!=null) q.offer(node.left);
                if(node.right!=null) q.offer(node.right);
            }
            res.add(level);
        }
        return res;
    }
}
```
## 2. Depth First Search traversal (Inorder)
```java
class Solution {
    List<Integer> arr = new ArrayList();
    public List<Integer> inorderTraversal(TreeNode root) {
        compute(root);
        return arr;
    }
    private void compute(TreeNode root){
        if(root == null) return;
        compute(root.left);
        arr.add(root.val);
        compute(root.right);
    }
}
```
## 3. Maximum Depth of Binary Tree - Using level order traversal
```java
class Solution {
    public int maxDepth(TreeNode root) {
        if(root == null) return 0;

        Queue<TreeNode> queue = new ArrayDeque();
        queue.offer(root);
        int depth = 0;

        while(!queue.isEmpty()){
            int size = queue.size();
            for(int i = 0; i<size; i++){
                TreeNode node = queue.poll();
                if(node.left!=null) queue.offer(node.left);
                if(node.right!=null) queue.offer(node.right);
            }
            depth++;
        }
        return depth;
    }
}
```
## 4. Balanced Binary Tree
```java
class Solution {
    public boolean isBalanced(TreeNode root) {
        return computeBalanced(root)!=-1;
    }

    private int computeBalanced(TreeNode node){
        if(node == null) return 0;

        int left = computeBalanced(node.left);
        if(left == -1) return -1;

        int right = computeBalanced(node.right);
        if(right == -1) return -1;

        if(Math.abs(left-right)>1) return -1;

        return 1+Math.max(left, right);
    } 
}
```
## 5. Lowest Common Ancestor
```java
class Solution {
    public TreeNode lowestCommonAncestor(TreeNode root, TreeNode p, TreeNode q) {
        if(root == null || root == p || root == q){
            return root;
        } 
        TreeNode left = lowestCommonAncestor(root.left, p, q);
        TreeNode right = lowestCommonAncestor(root.right, p, q);
        if(left == null) return right;
        else if(right == null) return left;
        else return root;
    }
}
```
## 6. Path Sum III
```java
class Solution {
    public int pathSum(TreeNode root, int targetSum) {
        Map<Long, Integer> map = new HashMap();
        map.put(0L, 1);
        return dfs(root, targetSum, 0L, map);
    }
    private int dfs(TreeNode node, int target, long sum, Map<Long, Integer> map){
        if(node == null) return 0;
        sum+=node.val;
        int ans = map.getOrDefault(sum-target, 0);
        map.put(sum, map.getOrDefault(sum, 0)+1);
        ans+=dfs(node.left, target, sum, map);
        ans+=dfs(node.right, target, sum, map);
        map.put(sum, map.get(sum)-1);
        return ans;

    }
}
```
