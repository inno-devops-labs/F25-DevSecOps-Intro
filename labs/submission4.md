# Task 1

**Comparison of Syft and Trivy**

### Package Type Distribution

Syft has reported a `binary` package type that Trivy does not mention. The
category only contains 1 package.

Apart from this, package types are the same across the two software tools:
what Syft names `deb` and `npm`, Trivy calls `debian 12.11` and `Node.js`,
respectively.

### Dependency Discovery Analysis

Syft found 3 more `Node.js` packages and 1 more `binary` package than Trivy.
Assuming that the reported packages are indeed used, Syft retrieved better data
than Trivy.

### License Discovery Analysis

Trivy separates licenses of OS packages from licenses of Node packages while
Syft does not.

The sets of license kinds that the tools report differ. Furthermore, the
reported numbers of packages that have a some license differ; for example,
according to Syft, 888 packages have the MIT license, but Trivy reports 878. It
is difficult to conclude that one tool is better than the other.


# Task 2
