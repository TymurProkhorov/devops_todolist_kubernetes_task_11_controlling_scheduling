1. Check taints

After executing bootstrap.sh should appear taints:

kubectl get nodes -l app=mysql -o custom-columns=NAME:.metadata.name,TAINTS:.spec.taints

Expect app=mysql:NoSchedule.

2. Check StatefulSet mysql
kubectl get pods -n mysql -o wide


All pods mysql should be only on nodes app=mysql.

On one node — not more than 1 pod.

If there are more replicas, than navailable nodes — pods Pending.

Check toleration:

kubectl get pod -n mysql -l app=mysql -o jsonpath='{.items[*].spec.tolerations}'


Should be key=app,value=mysql,effect=NoSchedule.

3. Check Deployment todoapp
kubectl get pods -n todoapp -o wide

Replicas should spread on different nodes (podAntiAffinity).

Preferable - on nodes app=todoapp (PreferredDuringSchedulingIgnoredDuringExecution).

4. Check spreading
echo "MySQL pods:"
kubectl get pod -n mysql -l app=mysql -o custom-columns=NAME:.metadata.name,NODE:.spec.nodeName --no-headers | sort -k2

echo "todoapp pods:"
kubectl get pod -n todoapp -l app=todoapp -o custom-columns=NAME:.metadata.name,NODE:.spec.nodeName --no-headers | sort -k2


Make sure pods on different apps are on different nodes.

5. Check through describe

For pending pod:

kubectl describe pod <pod-name> -n mysql | grep -A5 Events


Expect message like:
0/6 nodes are available: pod didn't match pod anti-affinity rules