# 1. 0/1 Knapsack

## i. Recursion

```java
class Solution {
    public int knapsack(int W, int val[], int wt[]) {
        int n = wt.length;
        return solve(W, val, wt, n);
    }
    
    public int solve(int W, int val[], int wt[], int n){
        if(n==0 || W == 0) return 0;
        if(wt[n-1]<=W){
            return Math.max(val[n-1]+solve(W-wt[n-1], val, wt, n-1), solve(W, val, wt, n-1));
        }
        if(wt[n-1]>W) return solve(W, val, wt, n-1);
        return 0;
    }
}
```

## ii. Memoization

```java
class Solution {
    public int knapsack(int W, int val[], int wt[]) {
        int n = wt.length;
        int[][] t = new int[n+1][W+1];
        for(int i = 0; i < n+1; i++){
            for(int j = 0; j<W+1; j++){
                t[i][j]=-1;
            }
        }
        return solve(W, val, wt, n, t);
    }
    
    public int solve(int W, int val[], int wt[], int n, int[][] t){
        if(n==0 || W == 0) return 0;
        if(t[n][W]!=-1) return t[n][W];
        if(t[n][W]==-1){
            if(wt[n-1]<=W){
            t[n][W] = Math.max(val[n-1]+solve(W-wt[n-1], val, wt, n-1, t), solve(W, val, wt, n-1, t));
            }
        if(wt[n-1]>W) t[n][W] = solve(W, val, wt, n-1, t);
    
        }
        return t[n][W];
    }
}
```
## iii. Tabulation
```java
class Solution {
	public int knapsack(int W, int val[], int wt[]) {
		//initialize the matrix
		int n = val.length;
		int[][] t = new int[n + 1][W + 1];
		
		//not needed, as Java assigns zero values
		/* for (int i = 0; i<n + 1; i++) {
			for (int j = 0; j<W + 1; j++) {
				t[i][j] = 0;
			}
		}
		*/
		
		for (int i = 1; i<n + 1; i++) {
			for (int j = 1; j<W + 1; j++) {
				if (wt[i - 1] <= j) {
					t[i][j] = Math.max(val[i - 1]+t[i - 1][j - wt[i - 1]], t[i - 1][j]);
				}
				else {
					t[i][j] = t[i - 1][j];
				}
				
			}
		}
		return t[n][W];
	}
}

```
