package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#HelmController: corev1.#Container & {
	_config: #Config

	name:            "helm-controller"
	image:           _config.controllers.helm
	imagePullPolicy: "IfNotPresent"
	securityContext: _config.securityContext
	ports: [{
		containerPort: 9795
		name:          "http-prom-hc"
		protocol:      "TCP"
	}, {
		containerPort: 9796
		name:          "healthz-hc"
		protocol:      "TCP"
	}]
	env: [{
		name:  "SOURCE_CONTROLLER_LOCALHOST"
		value: "localhost:9790"
	}, {
		name: "RUNTIME_NAMESPACE"
		valueFrom: fieldRef: fieldPath: "metadata.namespace"
	}]
	args: [
		"--watch-all-namespaces",
		"--log-level=\(_config.logLevel)",
		"--log-encoding=json",
		"--enable-leader-election=false",
		"--metrics-addr=:9795",
		"--health-addr=:9796",
		"--events-addr=http://localhost:9690",
		"--watch-label-selector=!sharding.fluxcd.io/key",
		"--concurrent=\(_config.reconcile.concurrent)",
		"--requeue-dependency=\(_config.reconcile.requeue)s",
		if _config.securityProfile == "restricted" {
			"--no-cross-namespace-refs"
		},
		if _config.securityProfile == "restricted" {
			"--default-service-account=\(_config.metadata.name)"
		},
	]
	readinessProbe: httpGet: {
		path: "/readyz"
		port: "healthz-hc"
	}
	livenessProbe: httpGet: {
		path: "/healthz"
		port: "healthz-hc"
	}
	resources: _config.resources
	volumeMounts: [{
		name:      "tmp"
		mountPath: "/tmp"
	}]
}
