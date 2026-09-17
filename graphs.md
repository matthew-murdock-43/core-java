## 1. BFS traversal of graph

Idea: Maintain a list of visited nodes along with a queue. Add the root node 0 and mark it as visited. Traverse through the queue till it is empty, adding the neighbor/adjacent nodes along the way.
``` java
class Solution {
	public ArrayList<Integer> bfs(ArrayList<ArrayList<Integer>> adj) {
		Queue<Integer> q = new LinkedList<Integer>();
		boolean[] vis = new boolean[adj.size()];

		q.offer(0);
		vis[0] = true;

		ArrayList<Integer> res = new ArrayList<Integer>();

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
## 2a. DFS traversal of graph - Iterative

Idea: Use stack instead of Queue above
``` java
class Solution {
	public ArrayList<Integer> dfs(ArrayList<ArrayList<Integer>> adj) {
		Deque<Integer> stack = new ArrayDeque<>();
		boolean[] vis = new boolean[adj.size()];

		stack.push(0);
		vis[0] = true;

		ArrayList<Integer> res = new ArrayList<Integer>();

		dfs(stack, res, vis, adj);
		return res;
	}
	
	private void dfs(Deque<Integer> stack, ArrayList<Integer> res, boolean[] vis, ArrayList<ArrayList<Integer>> adj) {
		while (!stack.isEmpty()) {
			Integer node = stack.pop();
			res.add(node);
			for (int neighbor : adj.get(node)) {
				if (!vis[neighbor]) {
					vis[neighbor] = true;
					stack.push(neighbor);
				}
			}
		}
	}
}

```


## 2b. DFS traversal of graph - Recursive

Idea: Maintain a list of visited nodes, start dfs with root node 0. DFS traversal - mark node as visited and add it to the result
``` java
class Solution {
    public ArrayList<Integer> dfs(ArrayList<ArrayList<Integer>> adj) {
        boolean[] visited = new boolean[adj.size()];
        ArrayList<Integer> res = new ArrayList<>();
        dfs(0, res, visited, adj);
        return res;
    }
    
    private void dfs(int node, ArrayList<Integer> res, boolean[] visited, ArrayList<ArrayList<Integer>> adj){
        visited[node]=true;
        res.add(node);
        for(Integer adjacentNode : adj.get(node)){
            if(!visited[adjacentNode]) dfs(adjacentNode, res, visited, adj);
        }
    }
}
```
## 3a. Topological sorting using DFS

Topological Sorting: Linear ordering of vertices such that if there is an edge between nodes _u_ and _v_, _u_ will appear before _v_ in the ordering

Idea: Visit first → explore all descendants; Finish later → push onto the stack; Pop the stack → vertices with prerequisites naturally come before their dependents.
```java
class Solution{
	public List<Integer> topologicalSorting(List<List<Integer>> dag){
		boolean[] visited = new boolean[dag.size()];
		Deque<Integer> st = new ArrayDeque<>();

		//looping through the visited array because a directed graph may not be connected
		for(int i = 0; i<dag.size(); i++){
			if(!visited[i]) dfs(dag, visited, i, st);
		}

		List<Integer> topo = new ArrayList<Integer>();
		while(!st.isEmpty()){
			topo.add(st.pop());
		}
		return topo;
	}
	
	private void dfs(List<List<Integer>> dag, boolean[] visited, int node, Deque<Integer> st){
		visited[node]=true;
		for(int neighbor : dag.get(node)){
			if(!visited[neighbor]) dfs(dag, visited, neighbor, st); 
		}
		//a node is pushed only after every node reachable from it has already been pushed.
		st.push(node);
	}
}
```
## 3b. Topological sorting using BFS (Kahn's algorithm)
Idea: Maintain an array of inDegree frequency. Reduce it everytime you visit and when it becomes zero, you add it to the queue. Loop through the queue, add the polled node to the res. Now loop through the adjacent nodes and reduce the inDegree. If it's inDegree == 0, add it to the queue.
```java
/*
  note: this algorithm does not require the usage of visited array
*/
class Solution {
    public ArrayList<Integer> topoSort(int V, int[][] edges) {
        //build an adjacency list from given edges
        ArrayList<ArrayList<Integer>> adj = new ArrayList<>();

        for (int i = 0; i < V; i++) adj.add(new ArrayList<>());

        int[] inDegree = new int[V];

        for (int[] edge : edges) {
            int u = edge[0];
            int v = edge[1];
            adj.get(u).add(v);
            inDegree[v]++;
        }

        Queue<Integer> q = new LinkedList<>();

        for (int i = 0; i < V; i++) {
            if (inDegree[i] == 0)
                q.offer(i);
        }

        ArrayList<Integer> res = new ArrayList<>();

        while (!q.isEmpty()) {
            int node = q.poll();
            res.add(node);

            for (int it : adj.get(node)) {
				//decrease inDegree of the neighbors of the node
                inDegree[it]--;
                if (inDegree[it] == 0)
                    q.offer(it);
            }
        }
        return res;
    }
}
```
## 4a. Detect cycle in an undirected graph using BFS

Queue<Pair> of node, parentNode; 
```java
record Pair(int first, int second) {}

class Solution {
    public boolean isCycle(int V, int[][] edges) {
        boolean[] vis = new boolean[V];
        //build an adjacency list from edges
        List<List<Integer>> adj = new ArrayList<>();
        
        for (int i = 0; i < V; i++){
            adj.add(new ArrayList<>());
        }
        
        for(int[] edge : edges){
            int u = edge[0];
            int v = edge[1];
            adj.get(u).add(v);
            adj.get(v).add(u);
        }

		//loop through vis to check all the nodes in case of disconneted graph
        for (int i = 0; i < V; i++) {
            if (!vis[i] && checkForCycle(i, vis, adj))
                return true;
        }

        return false;
    }

    private boolean checkForCycle(int src, boolean[] vis, List<List<Integer>> adj) {
		vis[src] = true;
		
		Queue<Pair> q = new LinkedList<>();
        q.offer(new Pair(src, -1));

        while (!q.isEmpty()) {
            Pair curr = q.poll();
            int node = curr.first();
            int parent = curr.second();

            for (int adjacentNode : adj.get(node)) {
                if (!vis[adjacentNode]) {
                    vis[adjacentNode] = true;
                    q.offer(new Pair(adjacentNode, node));
                } else if (adjacentNode != parent) {
                    return true;
                }
            }
        }

        return false;
    }
}
```
## 4b. Detect cycle in an undirected graph using DFS

dfs(node, parentNode, xx, xx)
```java
class Solution {
    public boolean isCycle(int V, int[][] edges) {
        boolean[] vis = new boolean[V];

		//create an adjacency list
        List<List<Integer>> adj = new ArrayList<>();
        for(int i = 0; i<V; i++) adj.add(new ArrayList<>());
        
        for(int[] edge : edges){
            int u = edge[0];
            int v = edge[1];
            adj.get(u).add(v);
            adj.get(v).add(u);
        }
        
        for(int i = 0; i<V; i++){
            if(!vis[i] && dfs(i, -1, adj, vis)) return true;
        }
        
        return false;
    }
    
    private boolean dfs(int node, int parent, List<List<Integer>> adj, boolean[] vis){
        vis[node] = true;
        for(int adjacentNode : adj.get(node)){
            if(!vis[adjacentNode]){
                if(dfs(adjacentNode, node, adj, vis)==true) return true; 
            } 
            //check adjacentNode != parent only when the adjacent node has already been visited
            else if(adjacentNode!=parent) return true;
        }
        return false;
    }
}
```
