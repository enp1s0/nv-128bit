# 128bit global memory access

[Dissecting the NVidia Turing T4 GPU via Microbenchmarking](https://arxiv.org/pdf/1903.07486.pdf)
にある128bitのGlobalメモリアクセスがどれほどのものか調査する

## 実験
- 128bitと32bit x4 によるGlobalメモリの読み込み時間の比較
- 大きさ `$ 2^{30} $` の `float` 配列にアクセス
- 1スレッドあたり4つの連続領域にアクセスする

### SASS
ちゃんと意図した通りのバイナリができている

- 128bit
```
LDG.E.128.SYS R4, [UR4] ;                  /* 0x00000004ff047981 */
```

- 32bit x4
```
LDG.E.SYS R0, [R2] ;                       /* 0x0000000002007381 */
                                           /* 0x000ea800001ee900 */
LDG.E.SYS R5, [R2+0x4] ;                   /* 0x0000040002057381 */
                                           /* 0x000ea800001ee900 */
LDG.E.SYS R6, [R2+0x8] ;                   /* 0x0000080002067381 */
                                           /* 0x000ee800001ee900 */
LDG.E.SYS R7, [R2+0xc] ;                   /* 0x00000c0002077381 */
                                           /* 0x000f2200001ee900 */
```

### 実験結果

- GeForce RTX 2080

```
    128bit read : 2.76 [s]
 32bit x 4 read : 13.651 [s]
```
