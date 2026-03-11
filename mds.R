library(edgeR)

counts <- read.table("htseq.ALL.counts.tsv", header=TRUE, row.names=1)

dge <- DGEList(counts=counts)

# normalize
dge <- calcNormFactors(dge)

pdf("mds_all.pdf")
# MDS plot
plotMDS(dge)
dev.off()



counts <- read.table("htseq.dedup.counts.tsv", header=TRUE, row.names=1)

dge <- DGEList(counts=counts)

# normalize
dge <- calcNormFactors(dge)

pdf("mds_dedup.pdf")
# MDS plot
plotMDS(dge)
dev.off()