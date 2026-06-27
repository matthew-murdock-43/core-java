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

