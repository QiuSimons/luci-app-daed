<h1 align="center">luci-app-daed</h1>
<p align="center">
  <img width="100" src="https://github.com/daeuniverse/dae/blob/main/logo.png?raw=true" />
</p>
<p align="center">
  <b>A Linux high-performance transparent proxy solution based on eBPF.</b>
</p>

-----------


## Build on OpenWrt official 25.12/SnapShots

### 1. Get Source
```bash
git clone https://github.com/QiuSimons/luci-app-daed package/dae
```

### 2. Install dependencies, refer to https://apt.llvm.org

```bash
apt-get update
apt-get install -y clang llvm npm
npm install -g pnpm
```

### 3. Change OpenWrt Source (Requirements for DAE to work)

- Enable eBPF support, add content to: `.config`
  ```
  CONFIG_DEVEL=y
  CONFIG_KERNEL_DEBUG_INFO=y
  CONFIG_KERNEL_DEBUG_INFO_REDUCED=n
  CONFIG_KERNEL_DEBUG_INFO_BTF=y
  CONFIG_KERNEL_CGROUPS=y
  CONFIG_KERNEL_CGROUP_BPF=y
  CONFIG_KERNEL_BPF_EVENTS=y
  CONFIG_BPF_TOOLCHAIN_HOST=y
  CONFIG_KERNEL_XDP_SOCKETS=y
  CONFIG_PACKAGE_kmod-xdp-sockets-diag=y
  ```

### 4. Build luci-app-daed

```bash
make menuconfig # choose LUCI -> Applications -> luci-app-daed
make package/dae/luci-app-daed/compile V=s # build luci-app-daed
```


## Preview
<p align="center">
<img width="800" src="https://github.com/QiuSimons/luci-app-daed/blob/master/PIC/1.jpg?raw=true" />
<img width="800" src="https://github.com/QiuSimons/luci-app-daed/blob/master/PIC/2.jpg?raw=true" />
</p>
