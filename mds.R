library(edgeR)

counts <- read.table("htseq.ALL.counts.tsv", header=TRUE, row.names=1, check.names=FALSE)

dge <- DGEList(counts=counts)

# normalize
dge <- calcNormFactors(dge)

pdf("report_dir/mds_all.pdf")
# MDS plot
plotMDS(dge, main="Multi-Dimensional Scaling Plot for all counts")
dev.off()

png("report_dir/mds_all.png")
# MDS plot
plotMDS(dge, main="Multi-Dimensional Scaling Plot for all counts")
dev.off()



counts <- read.table("htseq.dedup.counts.tsv", header=TRUE, row.names=1, check.names=FALSE)

dge <- DGEList(counts=counts)

# normalize
dge <- calcNormFactors(dge)

pdf("report_dir/mds_dedup.pdf")
# MDS plot
plotMDS(dge, main="Multi-Dimensional Scaling Plot for deduplicated counts")
dev.off()

png("report_dir/mds_dedup.png")
# MDS plot
plotMDS(dge, main="Multi-Dimensional Scaling Plot for deduplicated counts")
dev.off()