library(ggplot2)
library(ggrepel)

FC_setting = args[1] #setting fold change
pval_setting = args[2] #setting adj.p.val
file_path=arg[3]
result_path=arg[4]
FC_setting <- as.numeric(FC_setting)
pval_setting <- as.numeric(pval_setting)
logFC_setting <- log2(FC_setting)

file=read.table(file_path,header = T,sep="\t")

sigout <- subset(file, abs(log2FoldChange) > logFC_setting & padj < pval_setting)
upR <- sigout$SYMBOL[which(sigout$log2FoldChange > 0)]
downR <- sigout$SYMBOL[which(sigout$log2FoldChange < 0)]

volca <- ggplot(file,aes(log2FoldChange,-log10(padj))) + 
  geom_point(aes(color=ifelse((log2FoldChange > logFC_setting | log2FoldChange < -logFC_setting) & padj < pval_setting, "sign","non-sign")), cex = 1, alpha = 0.3) + 
  scale_colour_manual("Significance", values = c("steelblue","red")) +
  labs(title = 'Volcano plot', x = "log2 Fold Change", y = "-log10 adj.P.Val")+
  geom_text_repel(data = sigout, aes(label = rownames(sigout)), cex = 3,box.padding = unit(0.35, "lines"), point.padding = unit(0.3, "lines"))
ggsave(paste0(strsplit(file_path,"\\.")[[1]][1],"_","Volcano_plot.png"), volca, width = 7, height = 7)