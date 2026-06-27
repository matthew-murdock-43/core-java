## 1. DFS traversal of graph

``` java
class Solution {
	public ArrayList<Integer> dfs(ArrayList<ArrayList<Integer>> adj) {
		ArrayList<Integer> res = new ArrayList<Integer>();
		int v = adj.size();
		boolean[] vis = new boolean[v];
		vis[0] = true;
		dfs(0, vis, adj, res);
		return res;
	}
	
	private void dfs(int node, boolean[] vis, ArrayList<ArrayList<Integer>> adj, ArrayList<Integer> res) {
		vis[node] = true;
		res.add(node);
		for (Integer num : adj.get(node)) {
			if (!vis[num]) {
				dfs(num, vis, adj, res);
			}
		}
	}
}
```
## 2. BFS traversal of graph

``` java
class Solution {
	public ArrayList<Integer> bfs(ArrayList<ArrayList<Integer>> adj) {
		Queue<Integer> q = new LinkedList<Integer>();
		boolean[] vis = new boolean[adj.size()];
		ArrayList<Integer> res = new ArrayList<Integer>();
		vis[0] = true;
		q.offer(0);
		bfs(q, res, vis, adj);
		return res;
	}
	
	private void bfs(Queue<Integer> q, ArrayList<Integer> res, boolean[] vis, ArrayList<ArrayList<Integer>> adj) {
		while (!q.isEmpty()) {
			Integer node = q.poll();
			res.add(node);
			for (int neighbor : adj.get(node)) {
				if (!vis[neighbor]) {
					vis[neighbor] = true;
					q.offer(neighbor);
				}
			}
		}
	}
}

```
