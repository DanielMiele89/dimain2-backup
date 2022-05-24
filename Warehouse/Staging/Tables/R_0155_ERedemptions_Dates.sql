CREATE TABLE [Staging].[R_0155_ERedemptions_Dates] (
    [StartDate] DATETIME NULL,
    [EndDate]   DATETIME NULL
);


GO
CREATE CLUSTERED INDEX [cix_R_0155_ERedemptions_Dates_StartDate_Enddate]
    ON [Staging].[R_0155_ERedemptions_Dates]([StartDate] ASC, [EndDate] ASC);

