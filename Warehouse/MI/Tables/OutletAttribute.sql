CREATE TABLE [MI].[OutletAttribute] (
    [I]                 INT  IDENTITY (1, 1) NOT NULL,
    [ID]                INT  NULL,
    [OutletID]          INT  NOT NULL,
    [ReportMID_SplitID] INT  NOT NULL,
    [StartDate]         DATE NOT NULL,
    [EndDate]           DATE NOT NULL,
    [Mid_SplitID]       INT  NOT NULL
);


GO
CREATE CLUSTERED INDEX [IND]
    ON [MI].[OutletAttribute]([OutletID] ASC);

