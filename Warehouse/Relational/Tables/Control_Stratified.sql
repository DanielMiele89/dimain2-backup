CREATE TABLE [Relational].[Control_Stratified] (
    [id]                INT          IDENTITY (1, 1) NOT NULL,
    [CinID]             INT          NULL,
    [FanID]             INT          NULL,
    [PartnerID]         INT          NULL,
    [MonthID]           INT          NOT NULL,
    [PartnerGroupID]    INT          NULL,
    [ClientServicesRef] VARCHAR (40) NULL,
    PRIMARY KEY CLUSTERED ([id] ASC) WITH (FILLFACTOR = 90, DATA_COMPRESSION = PAGE),
    CONSTRAINT [unq_PFM] UNIQUE NONCLUSTERED ([FanID] ASC, [PartnerID] ASC, [PartnerGroupID] ASC, [ClientServicesRef] ASC, [MonthID] ASC) WITH (FILLFACTOR = 90, DATA_COMPRESSION = PAGE)
);


GO
CREATE NONCLUSTERED INDEX [idx_Monthid]
    ON [Relational].[Control_Stratified]([MonthID] ASC) WITH (FILLFACTOR = 90, DATA_COMPRESSION = PAGE);


GO
CREATE NONCLUSTERED INDEX [idx_Control]
    ON [Relational].[Control_Stratified]([CinID] ASC, [PartnerID] ASC, [MonthID] ASC) WITH (FILLFACTOR = 90, DATA_COMPRESSION = PAGE);


GO
GRANT ALTER
    ON OBJECT::[Relational].[Control_Stratified] TO [RetailerMonthlyReportUser]
    AS [dbo];

