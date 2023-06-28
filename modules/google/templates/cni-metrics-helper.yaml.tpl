---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: cni-metrics-helper
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cni-metrics-helper
subjects:
  - kind: ServiceAccount
    name: cni-metrics-helper
    namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: cni-metrics-helper
rules:
  - apiGroups: [""]
    resources:
      - nodes
      - pods
      - pods/proxy
      - services
      - resourcequotas
      - replicationcontrollers
      - limitranges
      - persistentvolumeclaims
      - persistentvolumes
      - namespaces
      - endpoints
    verbs: ["list", "watch", "get"]
  - apiGroups: ["extensions"]
    resources:
      - daemonsets
      - deployments
      - replicasets
    verbs: ["list", "watch"]
  - apiGroups: ["apps"]
    resources:
      - statefulsets
    verbs: ["list", "watch"]
  - apiGroups: ["batch"]
    resources:
      - cronjobs
      - jobs
    verbs: ["list", "watch"]
  - apiGroups: ["autoscaling"]
    resources:
      - horizontalpodautoscalers
    verbs: ["list", "watch"]
---
kind: Deployment
apiVersion: apps/v1
metadata:
  name: cni-metrics-helper
  namespace: kube-system
  labels:
    k8s-app: cni-metrics-helper
spec:
  selector:
    matchLabels:
      k8s-app: cni-metrics-helper
  template:
    metadata:
      labels:
        k8s-app: cni-metrics-helper
    spec:
      serviceAccountName: cni-metrics-helper
      containers:
      - image: 602401143452.dkr.ecr.us-west-2.amazonaws.com/cni-metrics-helper:${cni-metrics-helper_version}
        imagePullPolicy: Always
        name: cni-metrics-helper
        env:
          - name: USE_CLOUDWATCH
            value: "true"
      priorityClassName: "system-cluster-critical"
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: cni-metrics-helper
  namespace: kube-system
  annotations:
    eks.amazonaws.com/role-arn: "${cni-metrics-helper_role_arn_irsa}"
