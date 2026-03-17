library(edgeR)

counts <- read.table("htseq.ALL.counts.tsv", header=TRUE, row.names=1, check.names=FALSE)

dge <- DGEList(counts=counts)

# normalize
dge <- calcNormFactors(dge)

pdf("mds_all.pdf")
# MDS plot
plotMDS(dge, main="Multi-Dimensional Scaling Plot for all counts")
dev.off()

jpeg("mds_all.jpg")
# MDS plot
plotMDS(dge, main="Multi-Dimensional Scaling Plot for all counts")
dev.off()



counts <- read.table("htseq.dedup.counts.tsv", header=TRUE, row.names=1, check.names=FALSE)

dge <- DGEList(counts=counts)

# normalize
dge <- calcNormFactors(dge)

pdf("mds_dedup.pdf")
# MDS plot
plotMDS(dge, main="Multi-Dimensional Scaling Plot for deduplicated counts")
dev.off()

jpeg("mds_dedup.jpg")
# MDS plot
plotMDS(dge, main="Multi-Dimensional Scaling Plot for deduplicated counts")
dev.off()