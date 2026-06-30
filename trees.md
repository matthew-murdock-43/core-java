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

Almost every tree problem can be solved by asking:

"What information should each node return to its parent?"

This single idea solves most Medium/Hard tree problems.

## 0a. Height of a tree
```java
Class Solution{
    int height(TreeNode root) {

    if(root == null)
        return 0;

    int left = height(root.left);
    int right = height(root.right);

    return 1 + Math.max(left, right);
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
