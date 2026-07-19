# Sequential 3/5 Semantics

stage7_1_stable_code_identity_hash: `f3e84ecd77e63632d9e2eb0e70c0600fa0f370193ad27d6fa5717f0381700b4c`

- terminology: 3 个俯仰中间通道，每通道 5 个条件方位输出
- processing order: `ELEVATION_DBF_THEN_ELEVATION_CONDITIONED_AZIMUTH_DBF`
- first stage: `Zel=V'*Y`
- second stage: `z(b,c)=u(c|b)'*Zel(b,:)'`
- equivalent weight: `w(b,c)=kron(u(c|b),v(b))`
- output count: `B_out=B_el*B_az`
