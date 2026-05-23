library(here)
library(ggplot2)
library(patchwork)


set.seed(52654)
blog_directory = here("content", "blog", "2024-11-23-eeio-extrapolation")

#==============================#
#==== Inflation Adjustment ====#
#==============================#
#-- Create Dummy Data --#
#Set the years and emission factor
ef = 2.4
years = seq(2010, 2023)

#Calculate inflation relative to base year
n = length(years)
cpi_inflation = c(0, rnorm(n=n-1, 0.03, sd=0.02)) |> cumsum() + 1
ind_inflation = c(0, rnorm(n=n-1, 0.03, sd=0.08)) |> cumsum() + 1

#Create dataframe
df_inf = data.frame(year = rep(years, 2),
                    label = c(rep("CPI", n), rep("Industry Inflation", n)),
                    value = c(cpi_inflation*ef, ind_inflation*ef))


#-- Plot --#
#Plot diagram
p_inf <- ggplot(data=df_inf, aes(x=year, y=value, linetype=label)) +
  geom_line() + 
  ylab("kgCO2e / USD") +
  xlab("Year") +
  theme_minimal() +
  theme(legend.position="bottom",
        legend.title=element_blank())

#Save
ggsave(here(blog_directory, "ef_inflation_adjustment_volatile.png"))



#==================================#
#==== Exchange Rate Adjustment ====#
#==================================#
#-- Put Together Data --#
#Set the years and emission factor
ef <- 2.4
years <- seq(2010, 2023)

#Read in exchange rate data
f <- here(blog_directory, "fx_example.csv")
fx_df <- read.csv(f)

#Clean Data
colnames(fx_df) <- c("year", "value")
fx_df = fx_df[fx_df$year %in% as.character(years), ]
fx_df["year"] = as.numeric(fx_df$year)
fx_df["value"] = 1/as.numeric(fx_df$value)
fx_df["label"] = "USD to GBP Exchange Rate"

#Calculate inflation relative to base year
n <- length(years)
ef_df <- fx_df
ef_df["year"] = as.numeric(ef_df$year)
ef_df["value"] <- ef * (1/fx_df$value)
ef_df["label"] <- "Adjusted Emission Factor"

#Combine into single dataframe
df <- rbind(fx_df, ef_df)


#-- Plot --#
#Plot for exchange rate
p_fx <- ggplot(data=fx_df, aes(x=year, y=value, group=label)) +
  geom_line() + 
  ggtitle("Average USD to GBP Annual Exchange Rate") +
  ylab("Exchange Rate") +
  xlab("Year") +
  theme_minimal()

#Plot for emission factor adjusted by exchange rate
p_ef <- ggplot(data=ef_df, aes(x=year, y=value, group=label)) +
  geom_line() + 
  labs(title="Adjusted Emission Factor",
       subtitle=paste0("Emission Factor = ", ef, " kgCO2e/USD")) +
  ylab("kgCO2e / GBP") +
  xlab("Year") +
  theme_minimal()

#Combine FX adjustment and save
p_fx_adjustment <- p_fx/p_ef + plot_layout(ncol = 1, heights = c(1,1), axes = "collect")
ggsave(here(blog_directory, "ef_fx_adjustment.png"))


#==========================#
#==== Total Adjustment ====#
#==========================#
#-- Put Together Data --#
#Set Emission Factor
ef = 2.4
base_year = 2015

#Create three dataframes to plot
df_1 = df_inf[df_inf["label"] == "Industry Inflation", ]
df_2 = fx_df
df_3 = ef_df

#Make relevant adjustments to the dataframes
row_mask <- df_1$year == base_year
df_1["value"] <- (df_1$value / df_1$value[row_mask])*100
df_3["value"] <- ef * df_1$value/100 * (1/df_2$value)



#-- Plot --#
#Plot for exchange rate
p_1 <- ggplot(data=df_1, aes(x=year, y=value, group=label)) +
  geom_line() + 
  labs(title="Industry Specific Inflation") +
  ylab(paste0("Price Index\n(", base_year, " = 100)")) +
  xlab("Year") +
  theme_minimal()

#Plot for emission factor adjusted by exchange rate
p_3 <- ggplot(data=df_3, aes(x=year, y=value, group=label)) +
  geom_line() + 
  labs(title="Adjusted Emission Factor",
       subtitle=paste0(base_year, " emission factor of ", ef, "kgCO2e/USD")) +
  ylab("kgCO2e / GBP") +
  xlab("Year") +
  theme_minimal()

#Combine and save
p_combined_adjustment <- p_1/p_fx/p_3 + plot_layout(ncol = 1, heights = c(1,1,1), axes = "collect")
ggsave(here(blog_directory, "ef_combined_adjustment.png"))



