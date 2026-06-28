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
## 3a. Topological sorting using DFS
```java
class Solution{
	public List<Integer> topologicalSorting(List<List<Integer>> dag){
		boolean[] visited = new boolean[dag.size()];
		Stack<Integer> st = new Stack<Integer>();
		for(int i = 0; i<dag.size(); i++){
			if(!visited[i]) dfs(dag, visited, i, st);
		}
		List<Integer> topo = new ArrayList<Integer>();
		while(!st.isEmpty()){
			topo.add(st.pop());
		}
		return topo;
	}
	
	private void dfs(List<List<Integer>> dag, boolean[] visited, int node, Stack st){
		visited[node]=true;
		for(int neighbor : dag.get(node)){
			if(!visited[neighbor]) dfs(dag, visited, neighbor, st); 
		}
		st.push(node);
	}
}
```
