CREATE TABLE [Prototype].[Analysis_LastVisit] (
    [FromBrandID]           SMALLINT     NOT NULL,
    [ToBrandID]             SMALLINT     NOT NULL,
    [FromBrandName]         VARCHAR (50) NOT NULL,
    [ToBrandName]           VARCHAR (50) NOT NULL,
    [FromBrandID_LastSpend] INT          NULL,
    [ToBrandID_LastSpend]   INT          NULL,
    [Customers]             INT          NULL
);

