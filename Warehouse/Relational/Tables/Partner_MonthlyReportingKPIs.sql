CREATE TABLE [Relational].[Partner_MonthlyReportingKPIs] (
    [PartnerID]    INT            NOT NULL,
    [Year]         INT            NOT NULL,
    [KPI_1]        NVARCHAR (255) NULL,
    [KPI_1_Target] FLOAT (53)     NULL,
    [KPI_2]        NVARCHAR (255) NULL,
    [KPI_2_Target] FLOAT (53)     NULL,
    [KPI_3]        NVARCHAR (255) NULL,
    [KPI_3_Target] FLOAT (53)     NULL,
    [KPI_4]        NVARCHAR (255) NULL,
    [KPI_4_Target] FLOAT (53)     NULL,
    PRIMARY KEY CLUSTERED ([PartnerID] ASC, [Year] ASC)
);

