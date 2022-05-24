Create Procedure Staging.AdditionalCashbackRemoval
AS
Delete from [Relational].[AdditionalCashbackAward]
Where	[AdditionalCashbackAwardTypeID] = 2 and
		[TranDate] >= 'Dec 01, 2014'
