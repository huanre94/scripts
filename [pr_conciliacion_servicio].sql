USE [DBCONCILIACION]
GO
/****** Object:  StoredProcedure [dbo].[pr_conciliacion_servicio]    Script Date: 04/05/2017 17:35:48 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--exec pr_conciliacion_servicio @idconciliacion=223, 
--@vfechaconciliacion='20151027',@vhoraconciliacion='16:52:00',
--@opcion=1

--exec pr_conciliacion_servicio @idconfirmacion=15,
--@vfechainicial='20160901',@vfechafinal='20160930',
--@opcion=3 

ALTER procedure [dbo].[pr_conciliacion_servicio](
@idconciliacion int =null,						-- Código de conciliación
@idconfirmacion int =null,						-- Código de confirmación de malla de comisiones
@vfechainicial varchar(8)= null,				-- Fecha Inicial de corte de transacción
@vfechafinal varchar(8) =null,					-- Fecha final de corte de transacción
@vfechaconciliacion varchar(8)=null,			-- Fecha de Conciliación
@vhoraconciliacion varchar(10)=null,			-- Hora de Conciliación
@opcion int										-- 0: Conciliar la información
												-- 1: Enviar los datos conciliados a recaudación	
												-- 2: Envió de los datos conciliados y no conciliados a repositorio histórico	
												-- 3: Confirmación de malla de comisiones
)
as
begin
	declare @resultado int
	declare @iestado_conciliacion int
	declare @cantidadtrx int
	declare @fechadp1 varchar(8)    
	
	declare @diferencia1 int,@diferencia2 int
	
	declare  @vconciliadoeasyred char(1)		-- Indica si se concilio sin diferencias entre Easy-Red. Su valores puede ser:
												-- S: Conciliado sin difenrencias entre EasyCash con la Red
												-- N: Conciliado con diferencias entre EasyCash con la Red  
	
	declare  @vconciliadobancored char(1)		-- Indica si se concilión sin diferencias entre el Banco y la Red. Sus valores puedes ser:
												-- S: Conciliado sin diferencias entre el Banco con la Red
												-- N: Conciliado con diferencias entre el Banco con la Red
	
	declare @vconciliadoeasybanco char(1)		-- Indica si se concilio sin diferencias entre EasyCash y el Banco. Sus valores puden ser:
												--S: Conciliado sin diferencias entre EasyCash y el Banco
												--N: Conciliados con diferencias entre EasyCash y el Banco
	
	declare @dfechasistema datetime
	
	declare @icantidadtrxred int, @icantidadredeasy int
	declare @ncomisionred numeric(18,2), @ncomisioneasy numeric(18,2)
	
	set @icantidadtrxred=0
	set @icantidadredeasy=0
	
	set @ncomisionred=0
	set @ncomisioneasy=0
	
	set @iestado_conciliacion=0
	set @resultado=0
	set @cantidadtrx=0
	set @diferencia1=0
	set @diferencia2=0
	set @dfechasistema=null
	set @vconciliadoeasyred='S'					
	set @vconciliadobancored='S'
	set @vconciliadoeasybanco='S'
	
	if (@opcion=0) --Si se realiza el proceso de conciliación
	begin
		set @fechadp1 = (
						select valor from [192.168.3.28].[DBHEPS2000].dbo.dp_Parametro 
						where 
							campo = 'fechaDepuraciontrx'
						)   
	
		--Verificar la cantidad de transacciones ingresadas de la red
		select @resultado=icantidadtrxred 
		from tb_conciliacion_servicio
		where
			idconciliacion=@idconciliacion
		
		if(@resultado=0)--Si no hay transacciones ingresadas
		begin
			if @vfechafinal > @fechadp1
			begin
				--************Ingreso de Transacciones de la plataforma Hiper Log Diario****************************--
				insert into tptransactionlog(cTxMerchantId,cTxTerminalNum,ctxtid,cTxTxnNumber,fTxTxnDate,hTxTxnHour,
				cTxCompany,cTxStatus,cTxSettleStatus,cTxBatchId,cTxType,cTxForm,  cTxResultId,
				cTxResultExt,nTxRRN,nTxAutorization,cTxCurrency,nTxAmount,cTxPaymentType,cTxDiffPayType,
				nTxDiffPayMonth,cTxDiffPayMFree,nTxCardNumber, dTxSitCpyCompany,cTxOrigTxnNumber,fTxOrigTxnDate,
				fTxSettlementDate,cTxGroupId,cTxAcquirerId,cTxHost,cTxHostServ,cTxTerminalType,dTxAddData,
				cTxAccountType, cTxReadType,nTxIVA,nTxServicios,nTxPropina,nTxIntereses,nTxMontoFijo,
				nTxCargoAdic,cTxBusiness,cTxService,cTxCreateUser,fTxCreateDate,hTxCreateTime,                
				cTxModifyUser,fTxModifyDate,hTxModifyTime,nTxGenCounter,cTxQuotaCurr,nTxQuotas,fTxQuotaDate,
				nTxQuotaValue,cTxExchangeType,fTxExpDate,cTxTelefhoneNumber,     
				cTxUserCodePin,cTxIdMedio,cTxAdditionalData117,cTxAdditionalData118,cTxTellerCode,
				fTxAccountingDate,checked,cTxOrderId,cTxAddicionalData124,nombrecliente,       
				ciruccliente,ntxAutorizationHost,ntxAmountRec,ntxAmountSop,ntxAutorizationHost2,
				id_cabecera,conciliado,conciliado2,id_cliente_distribuidor,id_cliente_distribuidor_padre,
				ntxautorizationhostBPAC,estado)  
				select  
						A.cTxMerchantId,																		--1
						A.cTxTerminalNum,																		--2
						tm.dTrTerminalSN ctxtid	,																--3
						A.cTxTxnNumber,																			--4
						A.fTxTxnDate,																			--5
						A.hTxTxnHour,																			--6
						A.cTxCompany,																			--7
						A.cTxStatus,																			--8
						A.cTxSettleStatus,																		--9
						A.cTxBatchId,																			--10
						A.cTxType,																				--11
						A.cTxForm,																				--12
						A.cTxResultId,																			--13
						A.cTxResultExt,																			--14
						A.nTxRRN,																				--15
						A.nTxAutorization,																		--15
						A.cTxCurrency,																			--17
						A.nTxAmount,																			--18
						A.cTxPaymentType,																		--19
						A.cTxDiffPayType,																		--20
						A.nTxDiffPayMonth,																		--21
						A.cTxDiffPayMFree,																		--22
						A.nTxCardNumber,																		--23
						A.dTxSitCpyCompany,																		--24
						A.cTxOrigTxnNumber,																		--25
						A.fTxOrigTxnDate,																		--26        
						A.fTxSettlementDate,																	--27
						A.cTxGroupId,																			--28
						A.cTxAcquirerId,																		--29
						A.cTxHost,																				--30
						A.cTxHostServ,																			--31
						A.cTxTerminalType,																		--32
						A.dTxAddData,																			--33
						A.cTxAccountType,																		--34
						A.cTxReadType,																			--35
						A.nTxIVA,																				--36
						A.nTxServicios,																			--37
						A.nTxPropina,																			--38
						A.nTxIntereses,																			--39             
						A.nTxMontoFijo,																			--40
						A.nTxCargoAdic,																			--41
						A.cTxBusiness,																			--42
						A.cTxService,																			--43
						A.cTxCreateUser,																		--44
						A.fTxCreateDate,																		--45
						A.hTxCreateTime,																		--46
						A.cTxModifyUser,																		--47
						A.fTxModifyDate,																		--48
						A.hTxModifyTime,																		--49
						A.nTxGenCounter,																		--50
						A.cTxQuotaCurr,																			--51         
						A.nTxQuotas,																			--52
						A.fTxQuotaDate,																			--53
						A.nTxQuotaValue,																		--54
						A.cTxExchangeType,																		--55
						A.fTxExpDate,																			--56
						A.cTxTelefhoneNumber,																	--57
						A.cTxUserCodePin,																		--58
						'0' cTxIdMedio,																			--59
						A.cTxAdditionalData117,																	--60
						A.cTxAdditionalData118,																	--61
						A.cTxTellerCode,																		--62            
						ltrim(rtrim(A.fTxAccountingDate)) fTxAccountingDate,									--63
						A.checked,																				--64
						A.cTxOrderId,																			--65
						A.cTxAddicionalData124,																	--66
						A.nombrecliente,																		--67
						A.ciruccliente,																			--68
						
						'ntxAutorizationHost'=(												
												case   
													when len(rtrim(ltrim(A.ntxAutorizationhost))) <8 then   '2' +  replicate( '0',7 - len(rtrim(ltrim(A.ntxAutorizationhost)))) + rtrim(ltrim(A.ntxAutorizationhost))
													else ltrim(rtrim(A.ntxAutorizationhost))
												end
						),																						--69  
						A.ntxAmountRec,																			--70
						A.ntxAmountSop,	
																								--71
						'ntxAutorizationHost2'=(
												case isnull(ltrim(rtrim(A.ntxAutorizationHost2)),'00000000') 
													when '' then '00000000' 
													else isnull(ltrim(rtrim(A.ntxAutorizationHost2)),'00000000') 
												end
						) ,																						--72
						@idconciliacion as id_cabe, --@idcab ID_CABE,											--73
						'N' conciliado,																			--74
						'N' Conciliado2,																		--75
						null id_cliente_distribuidor,															--76
						null id_cliente_distribuidor_padre		,												--77
											
						case 
							when len(rtrim(ltrim(A.ntxAutorizationhost))) <8 then 
								substring( 
											'2' +  replicate( '0',7 - len(rtrim(ltrim(A.ntxAutorizationhost)))) + ltrim(rtrim(A.ntxAutorizationhost)),
											2,
											len('2' +  replicate( '0',7 - len(ltrim( rtrim(A.ntxAutorizationhost)))) + rtrim(ltrim(A.ntxAutorizationhost)))-1
								)
							else substring(ltrim(rtrim(A.ntxAutorizationhost)),2,len(ltrim(rtrim( A.ntxAutorizationhost)))-1 )
						end as ntxautorizationhostBPAC,															--78
						
						1																						--79
							
					from [192.168.3.28].dbheps2000.dbo.tptransactionlog_diario A  left join   [192.168.3.28].[DBHEPS2000].dbo.tmTerminal tm
					on
						A.cTxMerchantId= tm.cTrMerchantId and
						A.cTxTerminalNum= tm.cTrTerminalNum 
					where 
						( 
							(
								A.ctxbusiness>='33' and 
								A.ctxbusiness<='81'
							)
							
							or
							
							(
								A.ctxbusiness in ('88','89','90','91','92','93','94','95','96','97','98','A0','A1','A2','A3','A4','A5','A6')
							)
							
						) and 
						A.ctxresultext='00' and
						A.ctxtype='20' and 
						A.ctxstatus='0' and   
						A.cTxSettleStatus in('0','1') and  
						A.fTxCreateDate>=@vfechainicial and 
						A.fTxCreateDate<=@vfechafinal and
						not exists(
							select 1 from tptransactionlog x 
							where 
								x.cTxMerchantId=A.cTxMerchantId and 
								x.cTxTxnNumber=A.cTxTxnNumber and 
								x.ntxAutorizationHost=A.ntxAutorizationHost and
								x.ctxbusiness= A.ctxbusiness and
								x.fTxTxnDate=A.fTxTxnDate and
								x.cTxIdMedio='0'
						) and
						A.ntxAutorizationHost!=''
						
						
					--Ingreso de trx con estado Batch y que tenga un reintento de envio del trx
					insert into tptransactionlog(cTxMerchantId,cTxTerminalNum,ctxtid,cTxTxnNumber,fTxTxnDate,hTxTxnHour,
					cTxCompany,cTxStatus,cTxSettleStatus,cTxBatchId,cTxType,cTxForm,  cTxResultId,
					cTxResultExt,nTxRRN,nTxAutorization,cTxCurrency,nTxAmount,cTxPaymentType,cTxDiffPayType,
					nTxDiffPayMonth,cTxDiffPayMFree,nTxCardNumber, dTxSitCpyCompany,cTxOrigTxnNumber,fTxOrigTxnDate,
					fTxSettlementDate,cTxGroupId,cTxAcquirerId,cTxHost,cTxHostServ,cTxTerminalType,dTxAddData,
					cTxAccountType, cTxReadType,nTxIVA,nTxServicios,nTxPropina,nTxIntereses,nTxMontoFijo,
					nTxCargoAdic,cTxBusiness,cTxService,cTxCreateUser,fTxCreateDate,hTxCreateTime,                
					cTxModifyUser,fTxModifyDate,hTxModifyTime,nTxGenCounter,cTxQuotaCurr,nTxQuotas,fTxQuotaDate,
					nTxQuotaValue,cTxExchangeType,fTxExpDate,cTxTelefhoneNumber,     
					cTxUserCodePin,cTxIdMedio,cTxAdditionalData117,cTxAdditionalData118,cTxTellerCode,
					fTxAccountingDate,checked,cTxOrderId,cTxAddicionalData124,nombrecliente,       
					ciruccliente,ntxAutorizationHost,ntxAmountRec,ntxAmountSop,ntxAutorizationHost2,
					id_cabecera,conciliado,conciliado2,id_cliente_distribuidor,id_cliente_distribuidor_padre,
					ntxautorizationhostBPAC,estado)  
					select 
						A.cTxMerchantId,																		--1
						A.cTxTerminalNum,																		--2
						tm.dTrTerminalSN ctxtid	,																--3
						A.cTxTxnNumber,																			--4
						A.fTxTxnDate,																			--5
						A.hTxTxnHour,																			--6
						A.cTxCompany,																			--7
						A.cTxStatus,																			--8
						A.cTxSettleStatus,																		--9
						A.cTxBatchId,																			--10
						A.cTxType,																				--11
						A.cTxForm,																				--12
						A.cTxResultId,																			--13
						A.cTxResultExt,																			--14
						A.nTxRRN,																				--15
						A.nTxAutorization,																		--15
						A.cTxCurrency,																			--17
						A.nTxAmount,																			--18
						A.cTxPaymentType,																		--19
						A.cTxDiffPayType,																		--20
						A.nTxDiffPayMonth,																		--21
						A.cTxDiffPayMFree,																		--22
						A.nTxCardNumber,																		--23
						A.dTxSitCpyCompany,																		--24
						A.cTxOrigTxnNumber,																		--25
						A.fTxOrigTxnDate,																		--26        
						A.fTxSettlementDate,																	--27
						A.cTxGroupId,																			--28
						A.cTxAcquirerId,																		--29
						A.cTxHost,																				--30
						A.cTxHostServ,																			--31
						A.cTxTerminalType,																		--32
						A.dTxAddData,																			--33
						A.cTxAccountType,																		--34
						A.cTxReadType,																			--35
						A.nTxIVA,																				--36
						A.nTxServicios,																			--37
						A.nTxPropina,																			--38
						A.nTxIntereses,																			--39             
						A.nTxMontoFijo,																			--40
						A.nTxCargoAdic,																			--41
						A.cTxBusiness,																			--42
						A.cTxService,																			--43
						A.cTxCreateUser,																		--44
						A.fTxCreateDate,																		--45
						A.hTxCreateTime,																		--46
						A.cTxModifyUser,																		--47
						A.fTxModifyDate,																		--48
						A.hTxModifyTime,																		--49
						A.nTxGenCounter,																		--50
						A.cTxQuotaCurr,																			--51         
						A.nTxQuotas,																			--52
						A.fTxQuotaDate,																			--53
						A.nTxQuotaValue,																		--54
						A.cTxExchangeType,																		--55
						A.fTxExpDate,																			--56
						A.cTxTelefhoneNumber,																	--57
						A.cTxUserCodePin,																		--58
						'0' cTxIdMedio,																			--59
						A.cTxAdditionalData117,																	--60
						A.cTxAdditionalData118,																	--61
						A.cTxTellerCode,																		--62            
						ltrim(rtrim(A.fTxAccountingDate)) fTxAccountingDate,									--63
						A.checked,																				--64
						A.cTxOrderId,																			--65
						A.cTxAddicionalData124,																	--66
						A.nombrecliente,																		--67
						A.ciruccliente,																			--68
	
						'ntxAutorizationHost'=(												
												case   
													when len(rtrim(ltrim(A.ntxAutorizationhost))) <8 then   '2' +  replicate( '0',7 - len(rtrim(ltrim(A.ntxAutorizationhost)))) + rtrim(ltrim(A.ntxAutorizationhost))
													else ltrim(rtrim(A.ntxAutorizationhost))
												end
						),																						--69  
						A.ntxAmountRec,																			--70
						A.ntxAmountSop,	
																								--71
						'ntxAutorizationHost2'=(
												case isnull(ltrim(rtrim(A.ntxAutorizationHost2)),'00000000') 
													when '' then '00000000' 
													else isnull(ltrim(rtrim(A.ntxAutorizationHost2)),'00000000') 
												end
						) ,																						--72
						@idconciliacion as id_cabe, --@idcab ID_CABE,											--73
						'N' conciliado,																			--74
						'N' Conciliado2,																		--75
						null id_cliente_distribuidor,															--76
						null id_cliente_distribuidor_padre		,												--77
											
						case 
							when len(rtrim(ltrim(A.ntxAutorizationhost))) <8 then 
								substring( 
											'2' +  replicate( '0',7 - len(rtrim(ltrim(A.ntxAutorizationhost)))) + ltrim(rtrim(A.ntxAutorizationhost)),
											2,
											len('2' +  replicate( '0',7 - len(ltrim( rtrim(A.ntxAutorizationhost)))) + rtrim(ltrim(A.ntxAutorizationhost)))-1
								)
							else substring(ltrim(rtrim(A.ntxAutorizationhost)),2,len(ltrim(rtrim( A.ntxAutorizationhost)))-1 )
						end as ntxautorizationhostBPAC,															--78
						1			
					from [192.168.3.28].dbheps2000.dbo.tptransactionlog_diario A inner join [192.168.3.28].dbheps2000.dbo.tptransactionlog_diario B
					on
						A.ctxBatchid=B.ctxBatchid and
						A.ctxtype= B.ctxtype and
						A.ctxTxnNumber= B.ctxTxnNumber and
						A.ctxTerminalnum= B.ctxTerminalnum and
						A.ctxMerchantid= B.ctxMerchantid and
						B.CtxResultExt='00' and 
						B.ctxStatus='0' and
						B.CtxSettleStatus= '1' and
						B.ntxAutorizationhost='' and
						A.ctxbusiness=B.ctxbusiness and
						A.ctxresultext='00' and
						A.fTxTxnDate=B.fTxTxnDate

					left join   [192.168.3.28].[DBHEPS2000].dbo.tmTerminal tm
					on
						A.cTxMerchantId= tm.cTrMerchantId and
						A.cTxTerminalNum= tm.cTrTerminalNum 
					where
						A.fTxCreateDate>=@vfechainicial and 
						A.fTxCreateDate<=	convert(varchar,  
													dateadd(d,5, convert(datetime, @vfechafinal)),112
											) and 
						
						A.ctxtype='20' and 
						A.ctxResultExt='00' and
						A.ctxStatus='0' and
						A.CtxSettleStatus='9'	and
						A.ntxAutorizationhost!='' and
						
						( 
							(
								A.ctxbusiness>='33' and 
								A.ctxbusiness<='81'
							)
							
							or
							
							(
								A.ctxbusiness in ('88','89','90','91','92','93','94','95','96','97','98','A0','A1','A2','A3','A4','A5','A6')
							)
							
						)  
						
												
				--Ingreso de Transacciones que se fueron por Batch y no fueron considerados en el reintento del POS
				insert into tptransactionlog(cTxMerchantId,cTxTerminalNum,ctxtid,cTxTxnNumber,fTxTxnDate,hTxTxnHour,
				cTxCompany,cTxStatus,cTxSettleStatus,cTxBatchId,cTxType,cTxForm,  cTxResultId,
				cTxResultExt,nTxRRN,nTxAutorization,cTxCurrency,nTxAmount,cTxPaymentType,cTxDiffPayType,
				nTxDiffPayMonth,cTxDiffPayMFree,nTxCardNumber, dTxSitCpyCompany,cTxOrigTxnNumber,fTxOrigTxnDate,
				fTxSettlementDate,cTxGroupId,cTxAcquirerId,cTxHost,cTxHostServ,cTxTerminalType,dTxAddData,
				cTxAccountType, cTxReadType,nTxIVA,nTxServicios,nTxPropina,nTxIntereses,nTxMontoFijo,
				nTxCargoAdic,cTxBusiness,cTxService,cTxCreateUser,fTxCreateDate,hTxCreateTime,                
				cTxModifyUser,fTxModifyDate,hTxModifyTime,nTxGenCounter,cTxQuotaCurr,nTxQuotas,fTxQuotaDate,
				nTxQuotaValue,cTxExchangeType,fTxExpDate,cTxTelefhoneNumber,     
				cTxUserCodePin,cTxIdMedio,cTxAdditionalData117,cTxAdditionalData118,cTxTellerCode,
				fTxAccountingDate,checked,cTxOrderId,cTxAddicionalData124,nombrecliente,       
				ciruccliente,ntxAutorizationHost,ntxAmountRec,ntxAmountSop,ntxAutorizationHost2,
				id_cabecera,conciliado,conciliado2,id_cliente_distribuidor,id_cliente_distribuidor_padre,
				ntxautorizationhostBPAC,estado)  
				select 
						A.cTxMerchantId,																		--1
						A.cTxTerminalNum,																		--2
						tm.dTrTerminalSN ctxtid	,																--3
						A.cTxTxnNumber,																			--4
						A.fTxTxnDate,																			--5
						A.hTxTxnHour,																			--6
						A.cTxCompany,																			--7
						A.cTxStatus,																			--8
						A.cTxSettleStatus,																		--9
						A.cTxBatchId,																			--10
						A.cTxType,																				--11
						A.cTxForm,																				--12
						A.cTxResultId,																			--13
						A.cTxResultExt,																			--14
						A.nTxRRN,																				--15
						A.nTxAutorization,																		--15
						A.cTxCurrency,																			--17
						A.nTxAmount,																			--18
						A.cTxPaymentType,																		--19
						A.cTxDiffPayType,																		--20
						A.nTxDiffPayMonth,																		--21
						A.cTxDiffPayMFree,																		--22
						A.nTxCardNumber,																		--23
						A.dTxSitCpyCompany,																		--24
						A.cTxOrigTxnNumber,																		--25
						A.fTxOrigTxnDate,																		--26        
						A.fTxSettlementDate,																	--27
						A.cTxGroupId,																			--28
						A.cTxAcquirerId,																		--29
						A.cTxHost,																				--30
						A.cTxHostServ,																			--31
						A.cTxTerminalType,																		--32
						A.dTxAddData,																			--33
						A.cTxAccountType,																		--34
						A.cTxReadType,																			--35
						A.nTxIVA,																				--36
						A.nTxServicios,																			--37
						A.nTxPropina,																			--38
						A.nTxIntereses,																			--39             
						A.nTxMontoFijo,																			--40
						A.nTxCargoAdic,																			--41
						A.cTxBusiness,																			--42
						A.cTxService,																			--43
						A.cTxCreateUser,																		--44
						A.fTxCreateDate,																		--45
						A.hTxCreateTime,																		--46
						A.cTxModifyUser,																		--47
						A.fTxModifyDate,																		--48
						A.hTxModifyTime,																		--49
						A.nTxGenCounter,																		--50
						A.cTxQuotaCurr,																			--51         
						A.nTxQuotas,																			--52
						A.fTxQuotaDate,																			--53
						A.nTxQuotaValue,																		--54
						A.cTxExchangeType,																		--55
						A.fTxExpDate,																			--56
						A.cTxTelefhoneNumber,																	--57
						A.cTxUserCodePin,																		--58
						'0' cTxIdMedio,																			--59
						A.cTxAdditionalData117,																	--60
						A.cTxAdditionalData118,																	--61
						A.cTxTellerCode,																		--62            
						ltrim(rtrim(A.fTxAccountingDate)) fTxAccountingDate,									--63
						A.checked,																				--64
						A.cTxOrderId,																			--65
						A.cTxAddicionalData124,																	--66
						A.nombrecliente,																		--67
						A.ciruccliente,																			--68
	
						'ntxAutorizationHost'=(												
												case   
													when len(rtrim(ltrim(A.ntxAutorizationhost))) <8 then   '2' +  replicate( '0',7 - len(rtrim(ltrim(A.ntxAutorizationhost)))) + rtrim(ltrim(A.ntxAutorizationhost))
													else ltrim(rtrim(A.ntxAutorizationhost))
												end
						),																						--69  
						A.ntxAmountRec,																			--70
						A.ntxAmountSop,	
																								--71
						'ntxAutorizationHost2'=(
												case isnull(ltrim(rtrim(A.ntxAutorizationHost2)),'00000000') 
													when '' then '00000000' 
													else isnull(ltrim(rtrim(A.ntxAutorizationHost2)),'00000000') 
												end
						) ,																						--72
						@idconciliacion as id_cabe, --@idcab ID_CABE,											--73
						'N' conciliado,																			--74
						'N' Conciliado2,																		--75
						null id_cliente_distribuidor,															--76
						null id_cliente_distribuidor_padre		,												--77
											
						case 
							when len(rtrim(ltrim(A.ntxAutorizationhost))) <8 then 
								substring( 
											'2' +  replicate( '0',7 - len(rtrim(ltrim(A.ntxAutorizationhost)))) + ltrim(rtrim(A.ntxAutorizationhost)),
											2,
											len('2' +  replicate( '0',7 - len(ltrim( rtrim(A.ntxAutorizationhost)))) + rtrim(ltrim(A.ntxAutorizationhost)))-1
								)
							else substring(ltrim(rtrim(A.ntxAutorizationhost)),2,len(ltrim(rtrim( A.ntxAutorizationhost)))-1 )
						end as ntxautorizationhostBPAC,															--78
						1			
					from [192.168.3.28].dbheps2000.dbo.tptransactionlog_diario A left join   [192.168.3.28].[DBHEPS2000].dbo.tmTerminal tm
					on
						A.cTxMerchantId= tm.cTrMerchantId and
						A.cTxTerminalNum= tm.cTrTerminalNum 
					inner join [192.168.3.28].[DBHEPS2000].dbo.txBatch TB
					on
						TB.cBtMerchantId=A.cTxMerchantId and
						TB.cBtTerminalNum=A.cTxTerminalNum and
						TB.cBtBatchId= A.cTxBatchId
					where
						A.fTxCreateDate>=@vfechainicial and 
						A.fTxCreateDate<=	convert(varchar,  
													dateadd(d,1, convert(datetime, @vfechafinal)),112
											) and 
						
						A.ctxtype='20' and 
						A.ctxResultExt='00' and
						A.ctxStatus='0' and
						A.CtxSettleStatus='9'	and
						A.ntxAutorizationhost!='' and 
						not exists (
							select 1 from [192.168.3.28].dbheps2000.dbo.tptransactionlog_diario B
							where
								B.ctxBatchid=A.ctxBatchid and
								B.ctxTxnNumber=A.ctxTxnNumber and
								B.CtxResultExt='00'  and
								B.CtxSettleStatus= '1' and
								B.ntxAutorizationhost=A.ntxAutorizationhost and
								B.ctxtype=A.ctxtype and
								B.ctxTerminalnum= A.ctxTerminalnum and
								B.ctxtype= A.ctxtype and
								B.ctxtype='20' and
								B.ctxStatus='0' and
								B.fTxTxnDate=A.fTxTxnDate and
								A.ctxbusiness=B.ctxbusiness
						) and
						
						not exists(
							select 1 from tptransactionlog x 
							where 
								x.cTxMerchantId=A.cTxMerchantId and 
								x.cTxTxnNumber=A.cTxTxnNumber and 
								x.ntxAutorizationHost=A.ntxAutorizationHost and
								x.ctxbusiness= A.ctxbusiness and
								x.fTxTxnDate=A.fTxTxnDate and
								x.cTxIdMedio='0'
						) and
						
						( 
							(
								A.ctxbusiness>='33' and 
								A.ctxbusiness<='81'
							)
							
							or
							
							(
								A.ctxbusiness in ('88','89','90','91','92','93','94','95','96','97','98','A0','A1','A2','A3','A4','A5','A6')
							)
							
						)  
			end	
			else
			begin
				--************Ingreso de Transacciones de la plataforma Hiper Historico****************************--
				insert into tptransactionlog(cTxMerchantId,cTxTerminalNum,ctxtid,cTxTxnNumber,fTxTxnDate,hTxTxnHour,
				cTxCompany,cTxStatus,cTxSettleStatus,cTxBatchId,cTxType,cTxForm,  cTxResultId,
				cTxResultExt,nTxRRN,nTxAutorization,cTxCurrency,nTxAmount,cTxPaymentType,cTxDiffPayType,
				nTxDiffPayMonth,cTxDiffPayMFree,nTxCardNumber, dTxSitCpyCompany,cTxOrigTxnNumber,fTxOrigTxnDate,
				fTxSettlementDate,cTxGroupId,cTxAcquirerId,cTxHost,cTxHostServ,cTxTerminalType,dTxAddData,
				cTxAccountType, cTxReadType,nTxIVA,nTxServicios,nTxPropina,nTxIntereses,nTxMontoFijo,
				nTxCargoAdic,cTxBusiness,cTxService,cTxCreateUser,fTxCreateDate,hTxCreateTime,                
				cTxModifyUser,fTxModifyDate,hTxModifyTime,nTxGenCounter,cTxQuotaCurr,nTxQuotas,fTxQuotaDate,
				nTxQuotaValue,cTxExchangeType,fTxExpDate,cTxTelefhoneNumber,     
				cTxUserCodePin,cTxIdMedio,cTxAdditionalData117,cTxAdditionalData118,cTxTellerCode,
				fTxAccountingDate,checked,cTxOrderId,cTxAddicionalData124,nombrecliente,       
				ciruccliente,ntxAutorizationHost,ntxAmountRec,ntxAmountSop,ntxAutorizationHost2,
				id_cabecera,conciliado,conciliado2,id_cliente_distribuidor,id_cliente_distribuidor_padre,
				ntxautorizationhostBPAC,estado)  
				select  
						A.cTxMerchantId,																		--1
						A.cTxTerminalNum,																		--2
						tm.dTrTerminalSN ctxtid	,																--3
						A.cTxTxnNumber,																			--4
						A.fTxTxnDate,																			--5
						A.hTxTxnHour,																			--6
						A.cTxCompany,																			--7
						A.cTxStatus,																			--8
						A.cTxSettleStatus,																		--9
						A.cTxBatchId,																			--10
						A.cTxType,																				--11
						A.cTxForm,																				--12
						A.cTxResultId,																			--13
						A.cTxResultExt,																			--14
						A.nTxRRN,																				--15
						A.nTxAutorization,																		--15
						A.cTxCurrency,																			--17
						A.nTxAmount,																			--18
						A.cTxPaymentType,																		--19
						A.cTxDiffPayType,																		--20
						A.nTxDiffPayMonth,																		--21
						A.cTxDiffPayMFree,																		--22
						A.nTxCardNumber,																		--23
						A.dTxSitCpyCompany,																		--24
						A.cTxOrigTxnNumber,																		--25
						A.fTxOrigTxnDate,																		--26        
						A.fTxSettlementDate,																	--27
						A.cTxGroupId,																			--28
						A.cTxAcquirerId,																		--29
						A.cTxHost,																				--30
						A.cTxHostServ,																			--31
						A.cTxTerminalType,																		--32
						A.dTxAddData,																			--33
						A.cTxAccountType,																		--34
						A.cTxReadType,																			--35
						A.nTxIVA,																				--36
						A.nTxServicios,																			--37
						A.nTxPropina,																			--38
						A.nTxIntereses,																			--39             
						A.nTxMontoFijo,																			--40
						A.nTxCargoAdic,																			--41
						A.cTxBusiness,																			--42
						A.cTxService,																			--43
						A.cTxCreateUser,																		--44
						A.fTxCreateDate,																		--45
						A.hTxCreateTime,																		--46
						A.cTxModifyUser,																		--47
						A.fTxModifyDate,																		--48
						A.hTxModifyTime,																		--49
						A.nTxGenCounter,																		--50
						A.cTxQuotaCurr,																			--51         
						A.nTxQuotas,																			--52
						A.fTxQuotaDate,																			--53
						A.nTxQuotaValue,																		--54
						A.cTxExchangeType,																		--55
						A.fTxExpDate,																			--56
						A.cTxTelefhoneNumber,																	--57
						A.cTxUserCodePin,																		--58
						'0' cTxIdMedio,																			--59
						A.cTxAdditionalData117,																	--60
						A.cTxAdditionalData118,																	--61
						A.cTxTellerCode,																		--62            
						ltrim(rtrim(A.fTxAccountingDate)) fTxAccountingDate,									--63
						0 as checked,																			--64
						'' as cTxOrderId,																		--65
						'' as cTxAddicionalData124,																--66
						A.nombrecliente,																		--67
						A.ciruccliente,																			--68
						'ntxAutorizationHost'=(
												case   
													when len(rtrim(ltrim(A.ntxAutorizationhost))) <8 then   '2' +  replicate( '0',7 - len(rtrim(ltrim(A.ntxAutorizationhost)))) + rtrim(ltrim(A.ntxAutorizationhost))
													else ltrim(rtrim(A.ntxAutorizationhost))
												end
						),																						--69  
						A.ntxAmountRec,																			--70
						A.ntxAmountSop,																			--71
						'ntxAutorizationHost2'=(
												case isnull(ltrim(rtrim(A.ntxAutorizationHost2)),'00000000') 
													when '' then '00000000' 
													else isnull(ltrim(rtrim(A.ntxAutorizationHost2)),'00000000') 
												end
						) ,																						--72
						@idconciliacion as id_cabe, --@idcab ID_CABE,											--73
						'N' conciliado,																			--74
						'N' Conciliado2,																		--75
						null as id_cliente_distribuidor,															--76
						null as id_cliente_distribuidor_padre		,												--77
							
						case 
							when len(rtrim(ltrim(A.ntxAutorizationhost))) <8 then 
								substring( 
											'2' +  replicate( '0',7 - len(rtrim(ltrim(A.ntxAutorizationhost)))) + ltrim(rtrim(A.ntxAutorizationhost)),
											2,
											len('2' +  replicate( '0',7 - len(ltrim( rtrim(A.ntxAutorizationhost)))) + rtrim(ltrim(A.ntxAutorizationhost)))-1
								)
							else substring(ltrim(rtrim(A.ntxAutorizationhost)),2,len(ltrim(rtrim( A.ntxAutorizationhost)))-1 )
						end as ntxautorizationhostBPAC,															--78
	
						1																						--79
							
					from [192.168.3.28].dbo.tpTransactionLog_his A  inner join  [192.168.3.28].[DBHEPS2000].dbo.tmTerminal tm
					on
						A.cTxMerchantId= tm.cTrMerchantId and
						A.cTxTerminalNum= tm.cTrTerminalNum 
					where  
						
						( 
							(
								A.ctxbusiness>='33' and 
								A.ctxbusiness<='81'
							)
							
							or
							
							(
								A.ctxbusiness in ('88','89','90','91','92','93','94','95','96','97','98','A0','A1','A2','A3','A4','A5','A6')
							)
							
						)  and
						
						A.ctxresultext='00' and 
						A.ctxtype='20' and 
						A.ctxstatus='0' and 
						A.cTxSettleStatus in('0','1') and  
						A.fTxCreateDate>=@vfechainicial and 
						A.fTxCreateDate<=@vfechafinal and
						not exists(
							select 1 from tptransactionlog x 
							where 
								x.cTxMerchantId=A.cTxMerchantId and 
								x.cTxTxnNumber=A.cTxTxnNumber and 
								x.ntxAutorizationHost=A.ntxAutorizationHost and
								x.ctxbusiness=A.ctxbusiness and
								x.fTxTxnDate=A.fTxTxnDate and
								x.cTxIdMedio='0'
						) and
						A.ntxAutorizationHost!=''
				
				--Ingreso de las Trx que estuvieron en Batchupload y que hayan reintento en el POS	
				insert into tptransactionlog(cTxMerchantId,cTxTerminalNum,ctxtid,cTxTxnNumber,fTxTxnDate,hTxTxnHour,
				cTxCompany,cTxStatus,cTxSettleStatus,cTxBatchId,cTxType,cTxForm,  cTxResultId,
				cTxResultExt,nTxRRN,nTxAutorization,cTxCurrency,nTxAmount,cTxPaymentType,cTxDiffPayType,
				nTxDiffPayMonth,cTxDiffPayMFree,nTxCardNumber, dTxSitCpyCompany,cTxOrigTxnNumber,fTxOrigTxnDate,
				fTxSettlementDate,cTxGroupId,cTxAcquirerId,cTxHost,cTxHostServ,cTxTerminalType,dTxAddData,
				cTxAccountType, cTxReadType,nTxIVA,nTxServicios,nTxPropina,nTxIntereses,nTxMontoFijo,
				nTxCargoAdic,cTxBusiness,cTxService,cTxCreateUser,fTxCreateDate,hTxCreateTime,                
				cTxModifyUser,fTxModifyDate,hTxModifyTime,nTxGenCounter,cTxQuotaCurr,nTxQuotas,fTxQuotaDate,
				nTxQuotaValue,cTxExchangeType,fTxExpDate,cTxTelefhoneNumber,     
				cTxUserCodePin,cTxIdMedio,cTxAdditionalData117,cTxAdditionalData118,cTxTellerCode,
				fTxAccountingDate,checked,cTxOrderId,cTxAddicionalData124,nombrecliente,       
				ciruccliente,ntxAutorizationHost,ntxAmountRec,ntxAmountSop,ntxAutorizationHost2,
				id_cabecera,conciliado,conciliado2,id_cliente_distribuidor,id_cliente_distribuidor_padre,
				ntxautorizationhostBPAC,estado)  
				select 
						A.cTxMerchantId,																		--1
						A.cTxTerminalNum,																		--2
						tm.dTrTerminalSN ctxtid	,																--3
						A.cTxTxnNumber,																			--4
						A.fTxTxnDate,																			--5
						A.hTxTxnHour,																			--6
						A.cTxCompany,																			--7
						A.cTxStatus,																			--8
						A.cTxSettleStatus,																		--9
						A.cTxBatchId,																			--10
						A.cTxType,																				--11
						A.cTxForm,																				--12
						A.cTxResultId,																			--13
						A.cTxResultExt,																			--14
						A.nTxRRN,																				--15
						A.nTxAutorization,																		--15
						A.cTxCurrency,																			--17
						A.nTxAmount,																			--18
						A.cTxPaymentType,																		--19
						A.cTxDiffPayType,																		--20
						A.nTxDiffPayMonth,																		--21
						A.cTxDiffPayMFree,																		--22
						A.nTxCardNumber,																		--23
						A.dTxSitCpyCompany,																		--24
						A.cTxOrigTxnNumber,																		--25
						A.fTxOrigTxnDate,																		--26        
						A.fTxSettlementDate,																	--27
						A.cTxGroupId,																			--28
						A.cTxAcquirerId,																		--29
						A.cTxHost,																				--30
						A.cTxHostServ,																			--31
						A.cTxTerminalType,																		--32
						A.dTxAddData,																			--33
						A.cTxAccountType,																		--34
						A.cTxReadType,																			--35
						A.nTxIVA,																				--36
						A.nTxServicios,																			--37
						A.nTxPropina,																			--38
						A.nTxIntereses,																			--39             
						A.nTxMontoFijo,																			--40
						A.nTxCargoAdic,																			--41
						A.cTxBusiness,																			--42
						A.cTxService,																			--43
						A.cTxCreateUser,																		--44
						A.fTxCreateDate,																		--45
						A.hTxCreateTime,																		--46
						A.cTxModifyUser,																		--47
						A.fTxModifyDate,																		--48
						A.hTxModifyTime,																		--49
						A.nTxGenCounter,																		--50
						A.cTxQuotaCurr,																			--51         
						A.nTxQuotas,																			--52
						A.fTxQuotaDate,																			--53
						A.nTxQuotaValue,																		--54
						A.cTxExchangeType,																		--55
						A.fTxExpDate,																			--56
						A.cTxTelefhoneNumber,																	--57
						A.cTxUserCodePin,																		--58
						'0' cTxIdMedio,																			--59
						A.cTxAdditionalData117,																	--60
						A.cTxAdditionalData118,																	--61
						A.cTxTellerCode,																		--62            
						ltrim(rtrim(A.fTxAccountingDate)) fTxAccountingDate,									--63
						0 as checked,																			--64
						'' as cTxOrderId,																		--65
						'' cTxAddicionalData124,																	--66
						A.nombrecliente,																		--67
						A.ciruccliente,																			--68
	
						'ntxAutorizationHost'=(												
												case   
													when len(rtrim(ltrim(A.ntxAutorizationhost))) <8 then   '2' +  replicate( '0',7 - len(rtrim(ltrim(A.ntxAutorizationhost)))) + rtrim(ltrim(A.ntxAutorizationhost))
													else ltrim(rtrim(A.ntxAutorizationhost))
												end
						),																						--69  
						A.ntxAmountRec,																			--70
						A.ntxAmountSop,	
																								--71
						'ntxAutorizationHost2'=(
												case isnull(ltrim(rtrim(A.ntxAutorizationHost2)),'00000000') 
													when '' then '00000000' 
													else isnull(ltrim(rtrim(A.ntxAutorizationHost2)),'00000000') 
												end
						) ,																						--72
						@idconciliacion as id_cabe, --@idcab ID_CABE,											--73
						'N' conciliado,																			--74
						'N' Conciliado2,																		--75
						null id_cliente_distribuidor,															--76
						null id_cliente_distribuidor_padre		,												--77
											
						case 
							when len(rtrim(ltrim(A.ntxAutorizationhost))) <8 then 
								substring( 
											'2' +  replicate( '0',7 - len(rtrim(ltrim(A.ntxAutorizationhost)))) + ltrim(rtrim(A.ntxAutorizationhost)),
											2,
											len('2' +  replicate( '0',7 - len(ltrim( rtrim(A.ntxAutorizationhost)))) + rtrim(ltrim(A.ntxAutorizationhost)))-1
								)
							else substring(ltrim(rtrim(A.ntxAutorizationhost)),2,len(ltrim(rtrim( A.ntxAutorizationhost)))-1 )
						end as ntxautorizationhostBPAC,															--78
						1			
					from [192.168.3.28].dbo.tpTransactionLog_his A inner join [192.168.3.28].[DBHEPS2000_HIS].dbo.tpTransactionLog_his B
					on
						A.ctxBatchid=B.ctxBatchid and
						A.ctxtype= B.ctxtype and
						A.ctxTxnNumber= B.ctxTxnNumber and
						A.ctxTerminalnum= B.ctxTerminalnum and
						A.ctxMerchantid= B.ctxMerchantid and
						B.CtxResultExt='00' and 
						B.ctxStatus='0' and
						B.CtxSettleStatus= '1' and
						A.fTxTxnDate=B.fTxTxnDate and
						A.ctxbusiness=B.ctxbusiness and
						B.ntxAutorizationhost=''
					inner join   [192.168.3.28].[DBHEPS2000].dbo.tmTerminal tm
					on
						A.cTxMerchantId= tm.cTrMerchantId and
						A.cTxTerminalNum= tm.cTrTerminalNum 
					where
						A.fTxCreateDate>=@vfechainicial and 
						A.fTxCreateDate<=	convert(varchar,  
													dateadd(d,5, convert(datetime, @vfechafinal)),112
											) and 
						A.ctxtype='20' and 
						A.ctxResultExt='00' and
						A.ctxStatus='0' and
						A.CtxSettleStatus='9'	and
						A.ntxAutorizationhost!=''	and
						
						( 
							(
								A.ctxbusiness>='33' and 
								A.ctxbusiness<='81'
							)
							
							or
							
							(
								A.ctxbusiness in ('88','89','90','91','92','93','94','95','96','97','98','A0','A1','A2','A3','A4','A5','A6')
							)
							
						)  
						
						--A.ctxbusiness>='33'	and 
						--A.ctxbusiness<='81' 
				

				--Ingreso de Transacciones que se fueron por Batch y no fueron considerados en el reintento del POS
				insert into tptransactionlog(cTxMerchantId,cTxTerminalNum,ctxtid,cTxTxnNumber,fTxTxnDate,hTxTxnHour,
				cTxCompany,cTxStatus,cTxSettleStatus,cTxBatchId,cTxType,cTxForm,  cTxResultId,
				cTxResultExt,nTxRRN,nTxAutorization,cTxCurrency,nTxAmount,cTxPaymentType,cTxDiffPayType,
				nTxDiffPayMonth,cTxDiffPayMFree,nTxCardNumber, dTxSitCpyCompany,cTxOrigTxnNumber,fTxOrigTxnDate,
				fTxSettlementDate,cTxGroupId,cTxAcquirerId,cTxHost,cTxHostServ,cTxTerminalType,dTxAddData,
				cTxAccountType, cTxReadType,nTxIVA,nTxServicios,nTxPropina,nTxIntereses,nTxMontoFijo,
				nTxCargoAdic,cTxBusiness,cTxService,cTxCreateUser,fTxCreateDate,hTxCreateTime,                
				cTxModifyUser,fTxModifyDate,hTxModifyTime,nTxGenCounter,cTxQuotaCurr,nTxQuotas,fTxQuotaDate,
				nTxQuotaValue,cTxExchangeType,fTxExpDate,cTxTelefhoneNumber,     
				cTxUserCodePin,cTxIdMedio,cTxAdditionalData117,cTxAdditionalData118,cTxTellerCode,
				fTxAccountingDate,checked,cTxOrderId,cTxAddicionalData124,nombrecliente,       
				ciruccliente,ntxAutorizationHost,ntxAmountRec,ntxAmountSop,ntxAutorizationHost2,
				id_cabecera,conciliado,conciliado2,id_cliente_distribuidor,id_cliente_distribuidor_padre,
				ntxautorizationhostBPAC,estado)  
				select 
						A.cTxMerchantId,																		--1
						A.cTxTerminalNum,																		--2
						tm.dTrTerminalSN ctxtid	,																--3
						A.cTxTxnNumber,																			--4
						A.fTxTxnDate,																			--5
						A.hTxTxnHour,																			--6
						A.cTxCompany,																			--7
						A.cTxStatus,																			--8
						A.cTxSettleStatus,																		--9
						A.cTxBatchId,																			--10
						A.cTxType,																				--11
						A.cTxForm,																				--12
						A.cTxResultId,																			--13
						A.cTxResultExt,																			--14
						A.nTxRRN,																				--15
						A.nTxAutorization,																		--15
						A.cTxCurrency,																			--17
						A.nTxAmount,																			--18
						A.cTxPaymentType,																		--19
						A.cTxDiffPayType,																		--20
						A.nTxDiffPayMonth,																		--21
						A.cTxDiffPayMFree,																		--22
						A.nTxCardNumber,																		--23
						A.dTxSitCpyCompany,																		--24
						A.cTxOrigTxnNumber,																		--25
						A.fTxOrigTxnDate,																		--26        
						A.fTxSettlementDate,																	--27
						A.cTxGroupId,																			--28
						A.cTxAcquirerId,																		--29
						A.cTxHost,																				--30
						A.cTxHostServ,																			--31
						A.cTxTerminalType,																		--32
						A.dTxAddData,																			--33
						A.cTxAccountType,																		--34
						A.cTxReadType,																			--35
						A.nTxIVA,																				--36
						A.nTxServicios,																			--37
						A.nTxPropina,																			--38
						A.nTxIntereses,																			--39             
						A.nTxMontoFijo,																			--40
						A.nTxCargoAdic,																			--41
						A.cTxBusiness,																			--42
						A.cTxService,																			--43
						A.cTxCreateUser,																		--44
						A.fTxCreateDate,																		--45
						A.hTxCreateTime,																		--46
						A.cTxModifyUser,																		--47
						A.fTxModifyDate,																		--48
						A.hTxModifyTime,																		--49
						A.nTxGenCounter,																		--50
						A.cTxQuotaCurr,																			--51         
						A.nTxQuotas,																			--52
						A.fTxQuotaDate,																			--53
						A.nTxQuotaValue,																		--54
						A.cTxExchangeType,																		--55
						A.fTxExpDate,																			--56
						A.cTxTelefhoneNumber,																	--57
						A.cTxUserCodePin,																		--58
						'0' cTxIdMedio,																			--59
						A.cTxAdditionalData117,																	--60
						A.cTxAdditionalData118,																	--61
						A.cTxTellerCode,																		--62            
						ltrim(rtrim(A.fTxAccountingDate)) fTxAccountingDate,									--63
						0 as checked,																			--64
						'' as cTxOrderId,																		--65
						'' cTxAddicionalData124,	
						A.nombrecliente,																		--67
						A.ciruccliente,																			--68
	
						'ntxAutorizationHost'=(												
												case   
													when len(rtrim(ltrim(A.ntxAutorizationhost))) <8 then   '2' +  replicate( '0',7 - len(rtrim(ltrim(A.ntxAutorizationhost)))) + rtrim(ltrim(A.ntxAutorizationhost))
													else ltrim(rtrim(A.ntxAutorizationhost))
												end
						),																						--69  
						A.ntxAmountRec,																			--70
						A.ntxAmountSop,	
																								--71
						'ntxAutorizationHost2'=(
												case isnull(ltrim(rtrim(A.ntxAutorizationHost2)),'00000000') 
													when '' then '00000000' 
													else isnull(ltrim(rtrim(A.ntxAutorizationHost2)),'00000000') 
												end
						) ,																						--72
						@idconciliacion as id_cabe, --@idcab ID_CABE,											--73
						'N' conciliado,																			--74
						'N' Conciliado2,																		--75
						null id_cliente_distribuidor,															--76
						null id_cliente_distribuidor_padre		,												--77
											
						case 
							when len(rtrim(ltrim(A.ntxAutorizationhost))) <8 then 
								substring( 
											'2' +  replicate( '0',7 - len(rtrim(ltrim(A.ntxAutorizationhost)))) + ltrim(rtrim(A.ntxAutorizationhost)),
											2,
											len('2' +  replicate( '0',7 - len(ltrim( rtrim(A.ntxAutorizationhost)))) + rtrim(ltrim(A.ntxAutorizationhost)))-1
								)
							else substring(ltrim(rtrim(A.ntxAutorizationhost)),2,len(ltrim(rtrim( A.ntxAutorizationhost)))-1 )
						end as ntxautorizationhostBPAC,															--78
						1			
					from [192.168.3.28].[DBHEPS2000_HIS].dbo.tpTransactionLog_his A left join   [192.168.3.28].[DBHEPS2000].dbo.tmTerminal tm
					on
						A.cTxMerchantId= tm.cTrMerchantId and
						A.cTxTerminalNum= tm.cTrTerminalNum 
					inner join [192.168.3.28].[DBHEPS2000].dbo.txBatch TB
					on
						TB.cBtMerchantId=A.cTxMerchantId and
						TB.cBtTerminalNum=A.cTxTerminalNum and
						TB.cBtBatchId= A.cTxBatchId
					where
						A.fTxCreateDate>=@vfechainicial and 
						A.fTxCreateDate<=	convert(varchar,  
													dateadd(d,1, convert(datetime, @vfechafinal)),112
											) and 
						
						A.ctxtype='20' and 
						A.ctxResultExt='00' and
						A.ctxStatus='0' and
						A.CtxSettleStatus='9'	and
						A.ntxAutorizationhost!='' and 
						not exists (
							select 1 from [192.168.3.28].[DBHEPS2000_HIS].dbo.tpTransactionLog_his B
							where
								B.ctxBatchid=A.ctxBatchid and
								B.ctxTxnNumber=A.ctxTxnNumber and
								B.CtxResultExt='00'  and
								B.CtxSettleStatus= '1' and
								B.ntxAutorizationhost=A.ntxAutorizationhost and
								B.ctxtype=A.ctxtype and
								B.ctxTerminalnum= A.ctxTerminalnum and
								B.ctxtype= A.ctxtype and
								B.ctxtype='20' and
								B.ctxStatus='0' and
								B.fTxTxnDate=A.fTxTxnDate and
								A.ctxbusiness=B.ctxbusiness 
						) and
						
						not exists(
							select 1 from tptransactionlog x 
							where 
								x.cTxMerchantId=A.cTxMerchantId and 
								x.cTxTxnNumber=A.cTxTxnNumber and 
								x.ntxAutorizationHost=A.ntxAutorizationHost and
								x.ctxbusiness= A.ctxbusiness and
								x.fTxTxnDate=A.fTxTxnDate and
								x.cTxIdMedio='0'
						) and
						
						( 
							(
								A.ctxbusiness>='33' and 
								A.ctxbusiness<='81'
							)
							
							or
							
							(
								A.ctxbusiness in ('88','89','90','91','92','93','94','95','96','97','98','A0','A1','A2','A3','A4','A5','A6')
							)
							
						)  
						
						--A.ctxbusiness>='33'	and 
						--A.ctxbusiness<='81' 
							 
			end
			--*********Fin de Ingreso de Transacciones de la plataforma Hiper************************--

			--********Ingreso de las Transacciones de la plataforma MIRED****************************--
			
			--Traer las transacciones que estan en la tabla tb_log_trx_diario
			insert into tptransactionlog(cTxMerchantId,cTxTerminalNum,ctxtid,cTxTxnNumber,fTxTxnDate,hTxTxnHour,
			cTxCompany,cTxStatus,cTxSettleStatus,cTxBatchId,cTxType,cTxForm,  cTxResultId,
			cTxResultExt,nTxRRN,nTxAutorization,cTxCurrency,nTxAmount,cTxPaymentType,cTxDiffPayType,
			nTxDiffPayMonth,cTxDiffPayMFree,nTxCardNumber, dTxSitCpyCompany,cTxOrigTxnNumber,fTxOrigTxnDate,
			fTxSettlementDate,cTxGroupId,cTxAcquirerId,cTxHost,cTxHostServ,cTxTerminalType,dTxAddData,
			cTxAccountType, cTxReadType,nTxIVA,nTxServicios,nTxPropina,nTxIntereses,nTxMontoFijo,
			nTxCargoAdic,cTxBusiness,cTxService,cTxCreateUser,fTxCreateDate,hTxCreateTime,                
			cTxModifyUser,fTxModifyDate,hTxModifyTime,nTxGenCounter,cTxQuotaCurr,nTxQuotas,fTxQuotaDate,
			nTxQuotaValue,cTxExchangeType,fTxExpDate,cTxTelefhoneNumber,     
			cTxUserCodePin,cTxIdMedio,cTxAdditionalData117,cTxAdditionalData118,cTxTellerCode,
			fTxAccountingDate,checked,cTxOrderId,cTxAddicionalData124,nombrecliente,       
			ciruccliente,ntxAutorizationHost,ntxAmountRec,ntxAmountSop,ntxAutorizationHost2,
			id_cabecera,conciliado,conciliado2,id_cliente_distribuidor,id_cliente_distribuidor_padre,
			ntxautorizationhostBPAC,estado)            
			select 
					A.iso collate SQL_latin1_general_cp1_ci_as as iso,											--1
					'0000' collate SQL_latin1_general_cp1_ci_as as CtxTerminalnum	,							--2
					A.tid collate SQL_latin1_general_cp1_ci_as as tid,											--3
					A.numero_referencia collate SQL_latin1_general_cp1_ci_as as numero_referencia,				--4
					A.fecha_transaccion collate SQL_latin1_general_cp1_ci_as as fecha_transaccion,				--5
					A.hora_transaccion collate SQL_latin1_general_cp1_ci_as as hora_transaccion,				--6
					'' collate SQL_latin1_general_cp1_ci_as as cTxCompany,										--7
					A.estado collate SQL_latin1_general_cp1_ci_as as estado,									--8
					'0' collate SQL_latin1_general_cp1_ci_as as cTxSettleStatus,								--9   
					'' collate SQL_latin1_general_cp1_ci_as as cTxBatchId,										--10
					A.tipo_transaccion collate SQL_latin1_general_cp1_ci_as as tipo_transaccion,				--11
					'1' collate SQL_latin1_general_cp1_ci_as as cTxForm,										--12
					'000' collate SQL_latin1_general_cp1_ci_as as cTxResultId,									--13  
					A.respuesta collate SQL_latin1_general_cp1_ci_as as cTxResultExt,							--14
					0 nTxRRN,																					--15
					A.numero_autorizacion collate SQL_latin1_general_cp1_ci_as as numero_autorizacion,			--16
					'0' collate SQL_latin1_general_cp1_ci_as as cTxCurrency,									--17
					A.valor nTxAmount,																			--18
					'0' collate SQL_latin1_general_cp1_ci_as as cTxPaymentType,									--19				
					'0' collate SQL_latin1_general_cp1_ci_as as cTxDiffPayType,									--20
					0 as nTxDiffPayMonth,																		--21
					0 as cTxDiffPayMFree,																		--22
					'0' collate SQL_latin1_general_cp1_ci_as as nTxCardNumber,									--23
					'' collate SQL_latin1_general_cp1_ci_as as dTxSitCpyCompany,								--24 
					'' collate SQL_latin1_general_cp1_ci_as as cTxOrigTxnNumber,								--25
					'' collate SQL_latin1_general_cp1_ci_as as fTxOrigTxnDate,									--26
					'' collate SQL_latin1_general_cp1_ci_as as fTxSettlementDate,								--27
					null  as cTxGroupId,																		--28
					null as cTxAcquirerId,																		--29
					'' collate SQL_latin1_general_cp1_ci_as as cTxHost,											--30  
					'' collate SQL_latin1_general_cp1_ci_as as cTxHostServ,										--31
					'0' collate SQL_latin1_general_cp1_ci_as as cTxTerminalType,								--32
					'' collate SQL_latin1_general_cp1_ci_as as dTxAddData,										--33
					'00' collate SQL_latin1_general_cp1_ci_as as cTxAccountType,								--34 
					'T' collate SQL_latin1_general_cp1_ci_as as cTxReadType,									--35
					0.00 nTxIVA,																				--36
					0.00 nTxServicios,																			--37
					0.00 nTxPropina,																			--38
					0.00 nTxIntereses,																			--39
					0.00 nTxMontoFijo,																			--40
					0.00 nTxCargoAdic ,																			--41
					A.id_proveedor_facturacion,																	--42
					--A.id_proveedor collate SQL_latin1_general_cp1_ci_as,										--42
					A.id_producto collate SQL_latin1_general_cp1_ci_as,											--43
					A.usuario_distribuidor collate SQL_latin1_general_cp1_ci_as,								--44 
					A.fecha_transaccion collate SQL_latin1_general_cp1_ci_as,									--45
					A.hora_transaccion collate SQL_latin1_general_cp1_ci_as,									--46
					'' collate SQL_latin1_general_cp1_ci_as as cTxModifyUser,									--47
					'' collate SQL_latin1_general_cp1_ci_as as fTxModifyDate,									--48    
					'' collate SQL_latin1_general_cp1_ci_as as hTxModifyTime,									--49
					A.id nTxGenCounter,																			--50
					'0' collate SQL_latin1_general_cp1_ci_as as cTxQuotaCurr,									--51
					0 nTxQuotas,																				--52
					'00000000' collate SQL_latin1_general_cp1_ci_as as fTxQuotaDate,							--53
					0 nTxQuotaValue,																			--54
					'' collate SQL_latin1_general_cp1_ci_as as cTxExchangeType,									--55
					'' collate SQL_latin1_general_cp1_ci_as as fTxExpDate,										--56
					A.info_transaccion collate SQL_latin1_general_cp1_ci_as as info_transaccion,				--57
					'0000000000000000' collate SQL_latin1_general_cp1_ci_as as cTxUserCodePin,					--58
					'5' collate SQL_latin1_general_cp1_ci_as as cTxIdMedio,										--59
					'' collate SQL_latin1_general_cp1_ci_as as cTxAdditionalData117,							--60
					NULL cTxAdditionalData118,																	--61
					4242 cTxTellerCode,																			--62
					'' collate SQL_latin1_general_cp1_ci_as as fTxAccountingDate,								--63
					0 checked,																					--64
					'' collate SQL_latin1_general_cp1_ci_as as cTxOrderId,										--65
					
					(A.id_proveedor+A.id_producto+A.info_transaccion) collate SQL_latin1_general_cp1_ci_as 
					as cTxAddicionalData124,																	--66		 
					null as nombrecliente,																		--67																	
					null as ciruccliente,																		--68																	
					
					(
						case   
							when len(rtrim(ltrim(A.numero_autorizacion_host))) <8 then   '2' +  replicate( '0',7 - len(rtrim(ltrim(A.numero_autorizacion_host)))) + rtrim(ltrim(A.numero_autorizacion_host))
							else ltrim(rtrim(A.numero_autorizacion_host))
						end
					) collate SQL_latin1_general_cp1_ci_as ntxAutorizationHost,
					
					
					A.valor as ntxAmountRec,																	--70
					null as ntxAmountSop,																		--71  
					
					(
						case isnull(ltrim(rtrim(A.numero_autorizacion_host1)),'00000000') 
							when '' then '00000000' 
							else isnull(ltrim(rtrim(A.numero_autorizacion_host1)),'00000000') 
						end
					) collate SQL_latin1_general_cp1_ci_as ntxAutorizationHost2  ,								--72
					
					@idconciliacion as idcab,																	--73
					'N' conciliado,																				--74
					'N' Conciliado2,																			--75
					A.id_cliente_distribuidor,																	--76
										
					isnull([ContBroadnet].[dbo].[fn_idpadrepri_mired](A.id_cliente_distribuidor),
					A.id_cliente_distribuidor) as id_cliente_distribuidor_padre,								--77
					
					case 
						when len(rtrim(ltrim(A.numero_autorizacion_host))) <8 then 
								substring( 
											'2' +  replicate( '0',7 - len(rtrim(ltrim(A.numero_autorizacion_host)))) + ltrim(rtrim(A.numero_autorizacion_host)),
											2,
											len('2' +  replicate( '0',7 - len(ltrim( rtrim(A.numero_autorizacion_host)))) + rtrim(ltrim(A.numero_autorizacion_host)))-1
								)
							else substring(ltrim(rtrim(A.numero_autorizacion_host)),2,len(ltrim(rtrim( A.numero_autorizacion_host)))-1 )
					end as ntxautorizationhostBPAC,																--78
					1																							--79
			from /*[192.168.3.32].*/dbdistribuidor.dbo.tb_log_trx_diario  A
			where 
				( 
					(
						A.id_proveedor>='33' and 
						A.id_proveedor<='81'
					)
							
					or
							
					(
						A.id_proveedor in ('88','89','90','91','92','93','94','95','96','97','98','A0','A1','A2','A3','A4','A5','A6')
					)
							
				) and  
				
				respuesta='00' and 
				estado='0' and 
				tipo_transaccion='20' and 
				fecha_transaccion>=@vfechainicial AND--@FechaArchivos and 
				fecha_transaccion<=@vfechafinal and --@FechaArchivos2 
				not exists(
						select 1 from tptransactionlog x 
						where 
								x.cTxMerchantId=A.iso  collate SQL_latin1_general_cp1_ci_as and 
								--x.cTxTxnNumber=A.numero_referencia and 
								x.ntxAutorizationHost=A.numero_autorizacion_host  collate SQL_latin1_general_cp1_ci_as and
								x.fTxTxnDate=fecha_transaccion  collate SQL_latin1_general_cp1_ci_as and
								x.cTxBusiness=id_proveedor  collate SQL_latin1_general_cp1_ci_as and
								x.cTxIdMedio='5'
				) and
				
				isnull(A.numero_autorizacion_host,'')!=''
				
		
			--Traer las transacciones que quedaron pendientes del dia anterior de la tabla tb_log_trx
			insert into tptransactionlog(cTxMerchantId,cTxTerminalNum,ctxtid,cTxTxnNumber,fTxTxnDate,hTxTxnHour,
			cTxCompany,cTxStatus,cTxSettleStatus,cTxBatchId,cTxType,cTxForm,  cTxResultId,
			cTxResultExt,nTxRRN,nTxAutorization,cTxCurrency,nTxAmount,cTxPaymentType,cTxDiffPayType,
			nTxDiffPayMonth,cTxDiffPayMFree,nTxCardNumber, dTxSitCpyCompany,cTxOrigTxnNumber,fTxOrigTxnDate,
			fTxSettlementDate,cTxGroupId,cTxAcquirerId,cTxHost,cTxHostServ,cTxTerminalType,dTxAddData,
			cTxAccountType, cTxReadType,nTxIVA,nTxServicios,nTxPropina,nTxIntereses,nTxMontoFijo,
			nTxCargoAdic,cTxBusiness,cTxService,cTxCreateUser,fTxCreateDate,hTxCreateTime,                
			cTxModifyUser,fTxModifyDate,hTxModifyTime,nTxGenCounter,cTxQuotaCurr,nTxQuotas,fTxQuotaDate,
			nTxQuotaValue,cTxExchangeType,fTxExpDate,cTxTelefhoneNumber,     
			cTxUserCodePin,cTxIdMedio,cTxAdditionalData117,cTxAdditionalData118,cTxTellerCode,
			fTxAccountingDate,checked,cTxOrderId,cTxAddicionalData124,nombrecliente,       
			ciruccliente,ntxAutorizationHost,ntxAmountRec,ntxAmountSop,ntxAutorizationHost2,
			id_cabecera,conciliado,conciliado2,id_cliente_distribuidor,id_cliente_distribuidor_padre,
			ntxautorizationhostBPAC,estado)            
			select 
				A.iso collate SQL_latin1_general_cp1_ci_as as iso,											--1
				'0000' collate SQL_latin1_general_cp1_ci_as as CtxTerminalnum	,							--2
				A.tid collate SQL_latin1_general_cp1_ci_as as tid,											--3
				A.numero_referencia collate SQL_latin1_general_cp1_ci_as as numero_referencia,				--4
				A.fecha_transaccion collate SQL_latin1_general_cp1_ci_as as fecha_transaccion,				--5
				A.hora_transaccion collate SQL_latin1_general_cp1_ci_as as hora_transaccion,				--6
				'' collate SQL_latin1_general_cp1_ci_as as cTxCompany,										--7
				A.estado collate SQL_latin1_general_cp1_ci_as as estado,									--8
				'0' collate SQL_latin1_general_cp1_ci_as as cTxSettleStatus,								--9   
				'' collate SQL_latin1_general_cp1_ci_as as cTxBatchId,										--10
				A.tipo_transaccion collate SQL_latin1_general_cp1_ci_as as tipo_transaccion,				--11
				'1' collate SQL_latin1_general_cp1_ci_as as cTxForm,										--12
				'000' collate SQL_latin1_general_cp1_ci_as as cTxResultId,									--13  
				A.respuesta collate SQL_latin1_general_cp1_ci_as as cTxResultExt,							--14
				0 nTxRRN,																					--15
				A.numero_autorizacion collate SQL_latin1_general_cp1_ci_as as numero_autorizacion,			--16
				'0' collate SQL_latin1_general_cp1_ci_as as cTxCurrency,									--17
				A.valor nTxAmount,																			--18
				'0' collate SQL_latin1_general_cp1_ci_as as cTxPaymentType,									--19				
				'0' collate SQL_latin1_general_cp1_ci_as as cTxDiffPayType,									--20
				0 as nTxDiffPayMonth,																		--21
				0 as cTxDiffPayMFree,																		--22
				'0' collate SQL_latin1_general_cp1_ci_as as nTxCardNumber,									--23
				'' collate SQL_latin1_general_cp1_ci_as as dTxSitCpyCompany,								--24 
				'' collate SQL_latin1_general_cp1_ci_as as cTxOrigTxnNumber,								--25
				'' collate SQL_latin1_general_cp1_ci_as as fTxOrigTxnDate,									--26
				'' collate SQL_latin1_general_cp1_ci_as as fTxSettlementDate,								--27
				null  as cTxGroupId,																		--28
				null as cTxAcquirerId,																		--29
				'' collate SQL_latin1_general_cp1_ci_as as cTxHost,											--30  
				'' collate SQL_latin1_general_cp1_ci_as as cTxHostServ,										--31
				'0' collate SQL_latin1_general_cp1_ci_as as cTxTerminalType,								--32
				'' collate SQL_latin1_general_cp1_ci_as as dTxAddData,										--33
				'00' collate SQL_latin1_general_cp1_ci_as as cTxAccountType,								--34 
				'T' collate SQL_latin1_general_cp1_ci_as as cTxReadType,									--35
				0.00 nTxIVA,																				--36
				0.00 nTxServicios,																			--37
				0.00 nTxPropina,																			--38
				0.00 nTxIntereses,																			--39
				0.00 nTxMontoFijo,																			--40
				0.00 nTxCargoAdic ,																			--41
				A.id_proveedor_facturacion,																	--42
				--A.id_proveedor collate SQL_latin1_general_cp1_ci_as,										--42
				A.id_producto collate SQL_latin1_general_cp1_ci_as,											--43
				A.usuario_distribuidor collate SQL_latin1_general_cp1_ci_as,								--44 
				A.fecha_transaccion collate SQL_latin1_general_cp1_ci_as,									--45
				A.hora_transaccion collate SQL_latin1_general_cp1_ci_as,									--46
				'' collate SQL_latin1_general_cp1_ci_as as cTxModifyUser,									--47
				'' collate SQL_latin1_general_cp1_ci_as as fTxModifyDate,									--48    
				'' collate SQL_latin1_general_cp1_ci_as as hTxModifyTime,									--49
				A.id nTxGenCounter,																			--50
				'0' collate SQL_latin1_general_cp1_ci_as as cTxQuotaCurr,									--51
				0 nTxQuotas,																				--52
				'00000000' collate SQL_latin1_general_cp1_ci_as as fTxQuotaDate,							--53
				0 nTxQuotaValue,																			--54
				'' collate SQL_latin1_general_cp1_ci_as as cTxExchangeType,									--55
				'' collate SQL_latin1_general_cp1_ci_as as fTxExpDate,										--56
				A.info_transaccion collate SQL_latin1_general_cp1_ci_as as info_transaccion,				--57
				'0000000000000000' collate SQL_latin1_general_cp1_ci_as as cTxUserCodePin,					--58
				'5' collate SQL_latin1_general_cp1_ci_as as cTxIdMedio,										--59
				'' collate SQL_latin1_general_cp1_ci_as as cTxAdditionalData117,							--60
				NULL cTxAdditionalData118,																	--61
				4242 cTxTellerCode,																			--62
				'' collate SQL_latin1_general_cp1_ci_as as fTxAccountingDate,								--63
				0 checked,																					--64
				'' collate SQL_latin1_general_cp1_ci_as as cTxOrderId,										--65
				
				(A.id_proveedor+A.id_producto+A.info_transaccion) collate SQL_latin1_general_cp1_ci_as 
				as cTxAddicionalData124,																	--66		 
				null as nombrecliente,																		--67																	
				null as ciruccliente,																		--68																	
				
				(
					case   
						when len(rtrim(ltrim(A.numero_autorizacion_host))) <8 then   '2' +  replicate( '0',7 - len(rtrim(ltrim(A.numero_autorizacion_host)))) + rtrim(ltrim(A.numero_autorizacion_host))
						else ltrim(rtrim(A.numero_autorizacion_host))
					end
				) collate SQL_latin1_general_cp1_ci_as ntxAutorizationHost,									--69								

				
				
				A.valor as ntxAmountRec,																	--70
				null as ntxAmountSop,																		--71  
				
				(
					case ISNULL(ltrim(rtrim(A.numero_autorizacion_host1)),'00000000') 
						when '' then '00000000' 
						else ISNULL(ltrim(rtrim(A.numero_autorizacion_host1)),'00000000') 
					end
				) collate SQL_latin1_general_cp1_ci_as ntxAutorizationHost2  ,								--72
				
				@idconciliacion AS idcab,--@idcab,																		--73
				'N' conciliado,																				--74
				'N' Conciliado2,																			--75
				A.id_cliente_distribuidor,																	--76
				
				isnull([ContBroadnet].[dbo].[fn_idpadrepri_mired](A.id_cliente_distribuidor),
				A.id_cliente_distribuidor) as id_cliente_distribuidor_padre,								--77
				
				case 
					when len(rtrim(ltrim(A.numero_autorizacion_host))) <8 then 
								substring( 
											'2' +  replicate( '0',7 - len(rtrim(ltrim(A.numero_autorizacion_host)))) + ltrim(rtrim(A.numero_autorizacion_host)),
											2,
											len('2' +  replicate( '0',7 - len(ltrim( rtrim(A.numero_autorizacion_host)))) + rtrim(ltrim(A.numero_autorizacion_host)))-1
								)
					else substring(ltrim(rtrim(A.numero_autorizacion_host)),2,len(ltrim(rtrim( A.numero_autorizacion_host)))-1 )
				end as ntxautorizationhostBPAC,																--78
					
				1																							--79
		
			from /*[192.168.3.32].*/dbdistribuidor.dbo.tb_log_trx  A
			where 
				( 
					(
						A.id_proveedor>='33' and 
						A.id_proveedor<='81'
					)
							
					or
							
					(
						A.id_proveedor in ('88','89','90','91','92','93','94','95','96','97','98','A0','A1','A2','A3','A4','A5','A6')
					)
							
				) and
				
				
				respuesta='00' and 
				estado='0' and 
				tipo_transaccion='20' and 
				fecha_transaccion>=@vfechainicial AND--@FechaArchivos and 
				fecha_transaccion<=@vfechafinal and --@FechaArchivos2 
				not exists(
							select 1 from tptransactionlog x 
							where 
									x.cTxMerchantId=A.iso  collate SQL_latin1_general_cp1_ci_as and 
									X.ntxAutorizationHost=A.numero_autorizacion_host  collate SQL_latin1_general_cp1_ci_as  and
									x.fTxTxnDate=fecha_transaccion  collate SQL_latin1_general_cp1_ci_as and
									x.cTxBusiness=id_proveedor  collate SQL_latin1_general_cp1_ci_as and
									x.cTxIdMedio='5'
				) and
				isnull(numero_autorizacion_host,'')!=''
				
			--***********Fin de Ingreso de las Transacciones de la plataforma MIRED******************--
			
			select @cantidadtrx= count(*) from tptransactionlog
			where 
				fTxCreateDate>=@vfechainicial and
				fTxCreateDate<=@vfechafinal and
				ctxbusiness>='33'	and 
				ctxbusiness<='81' or (
					ctxbusiness in ('88','89','90','91','92','93','94','95','96','97','98','A0','A1','A2','A3','A4','A5','A6')
				) and
				id_cabecera=@idconciliacion
			
		
			--Actualizar la cantidad de registros migrados a la tabla de trabajo
			update tb_conciliacion_servicio with(rowlock)
			set icantidadtrxred=@cantidadtrx
			where
				idconciliacion=@idconciliacion
			
		end --Caso contrario de if(@resultado=0)	
		begin
			--Desconciliar la tabla de log de trabajo
			update tptransactionlog  with(rowlock)
			set 
				conciliado='N',
				conciliado2='N',
				FechaEasyCash=null,
				idbpac1=null,
				idbpac2=null,
				fTxAccountingDate=null
			where
				id_cabecera=@idconciliacion
		end --Fin de ff(@resultado=0)	
		
		--*********Conciliación de los registros de EasyCash contra la información de la Red**************--
	
		--Marcar las comisiones de EasyCash que estan en la red y actualizar el numero autorización de la comisión
		--grabada en el campo ntxAutorizationHost2 de la plataforma transaccional
		update T  with(rowlock)
		set 
			T.vconciliadored='S',
			T.vidproveedor= B.ctxbusiness,
			T.vsecuencialunicobanco2=	case T.vtipotransaccion
											when '00' then B.ntxAutorizationHost2
											else null
										end
		from TB_DETALLE_TRANSACCION_EASY T inner join tptransactionlog B
		on
			T.vsecuencialunico=B.ntxautorizationhost and
			T.idconciliacion= B.id_cabecera
		where
			T.idconciliacion=@idconciliacion
		
		--Marcar los registros de la plataforma que coincide con los
		--registros de EasyCash		
		update tptransactionlog  with(rowlock)
		set 
			conciliado='S',
			FechaEasyCash=b.vfechaTransaccion
		from tptransactionlog a inner join TB_DETALLE_TRANSACCION_EASY b 
		on 
			a.ntxautorizationhost=b.vsecuencialunico and 
			a.id_cabecera=b.idconciliacion
		where 
			a.id_cabecera=@idconciliacion and
			b.vtipotransaccion='20'
		
		select @diferencia1=count(1)  from TB_DETALLE_TRANSACCION_EASY 
		where 
			idconciliacion=@idconciliacion and vconciliadored='N'                  
		
		select @diferencia2=count(1) from tptransactionlog 
		where 
			id_cabecera=@idconciliacion and conciliado='N'     
		
		if (@diferencia1 >0 or  @diferencia2 >0)--Si no existe dieferencias entre EasyCash y la Red
		begin
			set @vconciliadoeasyred='N'		-- Diferencia encontradas entre EasyCash y la Red
			set @iestado_conciliacion=1		-- Se realizo la conciliación con diferencias			
		end
		--******Fin de Conciliación de los registros de EasyCash contra la información de la Red**********--
		
		
		--******Conciliación de los registros del Banco del Pacifico contra la información de la Red*******--
		
		--Marcar todos los pago que estan en el banco y la red
		update  T  with(rowlock)
		set
			T.vconciliadored='S',
			T.vidproveedor = TP.ctxbusiness
		from TB_DETALLE_TRANSACCION_BANCO T inner join tptransactionlog TP
		on
			TP.ntxautorizationhostBPAC=T.vreferencia and
			TP.id_cabecera=T.idconciliacion
		where
			T.idconciliacion=@idconciliacion and
			T.vtipotransaccion='20'
			
		--Marcar todas comisiones que estan en el banco y que lo registra la red campo ntxAutorizationHost2
		--y marcar en cada comisión en numero de autorización del pago
		update  T  with(rowlock)
		set
			T.vconciliadored='S',
			T.vreferencia2= TP.ntxautorizationhostBPAC,
			T.vidproveedor = TP.ctxbusiness
		from TB_DETALLE_TRANSACCION_BANCO T inner join tptransactionlog TP
		on
			TP.ntxAutorizationHost2=T.vreferencia and
			TP.id_cabecera=T.idconciliacion
		where
			T.idconciliacion=@idconciliacion and
			T.vtipotransaccion='00'
		
		--Marcar los pagos que se encuentra en la red y el banco
		update tptransactionlog  with(rowlock)
		set 
			conciliado2='S',
			idbpac1=b.idtrxbanco ,
			fTxAccountingDate=b.vfechaContable        
		from tptransactionlog a  inner join  TB_DETALLE_TRANSACCION_BANCO /*DetConciliacionBPAC*/ b 
		on 
			a.ntxautorizationhostBPAC=b.vreferencia and 
			a.id_cabecera=b.idconciliacion  
		where 
			a.id_cabecera=@idconciliacion and
			b.vtipotransaccion='20'
		
		
		--Actualizar el campo idbpac2 con el id de una de las comisiones del banco
		update tptransactionlog  with(rowlock)
			set idbpac2=b.idtrxbanco                  
		from tptransactionlog a inner join TB_DETALLE_TRANSACCION_BANCO b   
		on	
			a.id_cabecera=b.idconciliacion  and
			a.ntxAutorizationHost2=b.vreferencia             
		where 
			a.id_cabecera=@idconciliacion and 
			b.vtipotransaccion='00'
			
		set @diferencia1=0
		set @diferencia2=0	
		
		select @diferencia1=count(1)  from TB_DETALLE_TRANSACCION_BANCO 
		where 
			idconciliacion=@idconciliacion and 
			vconciliadored='N'  and 
			vvalida !='S'              
		
		select @diferencia2=count(1) from tptransactionlog 
		where 
			id_cabecera=@idconciliacion and conciliado2='N'   
		
		if (@diferencia1>0 or @diferencia2>0)
		begin
			set @vconciliadobancored='N'	-- Diferencia encontradas entre Banco y la Red
			set @iestado_conciliacion=1		-- Se realizo la conciliación con diferencias	
		end
			
		--***Fin de Conciliación de los registros del Banco del Pacífico contra la información de la Red***--
		
		
		--***************************Conciliar Plataforma del Banco y Plataforma EasyCash*******************--
		
		--Marcar pagos del Banco que estan incluidor en EasyCash
		update A  with(rowlock)
			set 
				A.vconciliadoeasy='S',
				A.ideasy=B.idtrxeasy,
				A.vidproveedor= COALESCE(A.vidproveedor, B.vidproveedor)
		from TB_DETALLE_TRANSACCION_BANCO A inner join TB_DETALLE_TRANSACCION_EASY B
		on
			A.vreferencia=B.vsecuencialunicobanco and
			A.idconciliacion=B.idconciliacion
		where
			A.idconciliacion=@idconciliacion and
			A.vtipotransaccion='20' and
			B.vtipotransaccion='20'
			
		--Marcar las comisiones que estan en EasyCash registradas en el campo vsecuencialunicobanco2
		update TB_DETALLE_TRANSACCION_BANCO  with(rowlock)
			set 
				vconciliadoeasy='S'  ,
				vidproveedor= isnull(A.vidproveedor, B.vidproveedor)
		FROM TB_DETALLE_TRANSACCION_BANCO A   INNER JOIN TB_DETALLE_TRANSACCION_EASY B 
		ON 
			A.vreferencia=b.vsecuencialunicobanco2 and 
			A.idconciliacion=B.idconciliacion   
		where 
			A.idconciliacion=@idconciliacion and
			A.vconciliadoeasy='N' and
			A.vtipotransaccion='00' and
			B.vtipotransaccion='00'
		--*************************Fin de Conciliar Plataforma del Banco y Plataforma EasyCash***************--
		
		
		--***********Conciliación de la plataforma EasyCash y la plataforma del Banco de Pacífico*************--
	
        --Marcar los pagos de la plataforma EasyCash que son incluidos en la plataforma del Banco
        update TB_DETALLE_TRANSACCION_EASY  with(rowlock)
        set
			vconciliadobanco='S',
          	idbpac= B.idtrxbanco
        from TB_DETALLE_TRANSACCION_EASY A inner join TB_DETALLE_TRANSACCION_BANCO B
        on
			A.vsecuencialunicobanco=B.vreferencia and
			A.idconciliacion= B.idconciliacion
		where
			A.idconciliacion=@idconciliacion and
			A.vtipotransaccion='20'
		
		
		--Marcar las comisiones de la plataforma easycash registradas en el campo vsecuencialunicobanco2 
		--que son incluidos en la plataforma del Banco
		update TB_DETALLE_TRANSACCION_EASY  with(rowlock)
			set 
				vconciliadobanco='S'--,
				--idbpac=b.idtrxbanco                  
		from TB_DETALLE_TRANSACCION_EASY a   INNER JOIN TB_DETALLE_TRANSACCION_BANCO b 
		on 
			a.vsecuencialunicobanco2=b.vreferencia and
			a.idconciliacion=b.idconciliacion
		where 
			a.idconciliacion=@idconciliacion and
			a.vtipotransaccion='00'   
		
		set @diferencia1=0
		set @diferencia2=0	
				
		select @diferencia1=count(1) from TB_DETALLE_TRANSACCION_BANCO
		where
			idconciliacion=@idconciliacion and
			vconciliadoeasy='N' and vvalida!='S'
		
		select @diferencia2=count(1) from TB_DETALLE_TRANSACCION_EASY
		where
			idconciliacion=@idconciliacion and
			vconciliadobanco='N'
		
		
		if(@diferencia1>0 or @diferencia2>0)
		begin
			set @iestado_conciliacion=1
			set @vconciliadoeasybanco='N'
		end 
		--*****************Fin de Conciliacion de la plataforma EasyCash y la plataforma Baco del Pacífico****--
		
		--************************Rutina de Regularización de Registros de EasyCash***************************--

		--***Buscar Registros en la Plataforma Hiper
		
		--Verificar Log historico diario tanto de Pago y Comisión
		update E  with(rowlock)
		set
			E.ipendiente=1	
		from tb_detalle_transaccion_easy E  inner join  [192.168.3.28].dbheps2000.dbo.tptransactionlog_diario T
		on
			ltrim(rtrim(E.vsecuencialunico))=ltrim(rtrim(T.ntxautorizationhost))   
		where 
			
			( 
				(
					T.ctxbusiness>='33' and 
					T.ctxbusiness<='81'
				)
							
				or
							
				(
					T.ctxbusiness in ('88','89','90','91','92','93','94','95','96','97','98','A0','A1','A2','A3','A4','A5','A6')
				)
							
			) and
			
			T.ctxResultExt='00' and
			T.ctxType='20' and
			T.CtxStatus='0' and
			E.idconciliacion=@idconciliacion and 
			E.vconciliadored='N' and
			T.ftxCreateDate >= 
				convert(varchar,  
				dateadd(d,0, convert(datetime, vfechatransaccion)),112
			) and 
			
			T.ftxCreateDate <= 
				convert(varchar,  
				dateadd(d,5, convert(datetime, vfechatransaccion)),112
			) and 
			
			T.ctxSettleStatus!='9'  AND
			T.ntxAutorizationhost!=''
			
		
		--Incluir los pagos y comisiones con BatchUpload
		update E  with(rowlock)
		set
			E.ipendiente=1	
		from tb_detalle_transaccion_easy E  inner join  [192.168.3.28].dbheps2000.dbo.tptransactionlog_diario T
		on
			ltrim(rtrim(E.vsecuencialunico))=ltrim(rtrim(T.ntxautorizationhost))  
		inner join [192.168.3.28].dbheps2000.dbo.tptransactionlog_diario B
		on
			T.ctxType=B.ctxType and
			T.ctxBatchid=B.ctxBatchid and
			T.ctxTxnNumber= B.ctxTxnNumber and
			T.ctxTerminalnum= B.ctxTerminalnum and
			T.ctxMerchantid= B.ctxMerchantid and
			B.CtxResultExt='00' and 
			B.ctxStatus='0' and
			B.CtxSettleStatus= '1'	
			and B.ntxAutorizationhost=''
		where 			
			( 
				(
					T.ctxbusiness>='33' and 
					T.ctxbusiness<='81'
				)
							
				or
							
				(
					T.ctxbusiness in ('88','89','90','91','92','93','94','95','96','97','98','A0','A1','A2','A3','A4','A5','A6')
				)
							
			) and

			
			T.ctxResultExt='00' and
			T.ctxType='20' and
			T.CtxStatus='0' and
			E.idconciliacion=@idconciliacion and 
			E.vconciliadored='N' and
			T.ftxCreateDate >= 
				convert(varchar,  
				dateadd(d,0, convert(datetime, vfechatransaccion)),112
			) and 
			T.ftxCreateDate <= 
				convert(varchar,  
				dateadd(d,5, convert(datetime, vfechatransaccion)),112
			) and 
			T.ctxSettleStatus='9'  and
			T.ntxAutorizationhost!=''
		

		if @vfechafinal < @fechadp1 --Revisar Log Historico Total para Pago y Comisión
		begin
			update E  with(rowlock)
			set
				E.ipendiente=1
			from tb_detalle_transaccion_easy E  inner join  [192.168.3.28].[DBHEPS2000_HIS].dbo.tpTransactionLog_his T
			on
				ltrim(rtrim(E.vsecuencialunico))=ltrim(rtrim(T.ntxautorizationhost))   
			where 
				
				( 
					(
						T.ctxbusiness>='33' and 
						T.ctxbusiness<='81'
					)
							
					or
							
					(
						T.ctxbusiness in ('88','89','90','91','92','93','94','95','96','97','98','A0','A1','A2','A3','A4','A5','A6')
					)
							
				) and

				
				T.ctxResultExt='00' and
				T.ctxType='20' and
				T.CtxStatus='0' and
				E.idconciliacion=@idconciliacion and 
				E.vconciliadored='N'  and
				T.ftxCreateDate >= 
					convert(varchar,  
					dateadd(d,0, convert(datetime, vfechatransaccion)),112
				) and 
				
				T.ftxCreateDate <= 
					convert(varchar,  
					dateadd(d,5, convert(datetime, vfechatransaccion)),112
				) and 
				
				T.ctxSettleStatus!='9'  and
				T.ntxAutorizationhost!=''
				
			--Incluir los pagos y comisiones con BatchUpload
			update E  with(rowlock)
			set
				E.ipendiente=1	
			from tb_detalle_transaccion_easy E  inner join  [192.168.3.28].[DBHEPS2000_HIS].dbo.tpTransactionLog_his T
			on
				ltrim(rtrim(E.vsecuencialunico))=ltrim(rtrim(T.ntxautorizationhost))  
			inner join [192.168.3.28].[DBHEPS2000_HIS].dbo.tpTransactionLog_his B
			on
				T.ctxType=B.ctxType and
				T.ctxBatchid=B.ctxBatchid and
				T.ctxTxnNumber= B.ctxTxnNumber and
				T.ctxTerminalnum= B.ctxTerminalnum and
				T.ctxMerchantid= B.ctxMerchantid and
				B.CtxResultExt='00' and 
				B.ctxStatus='0' and
				B.CtxSettleStatus= '1'	
				and B.ntxAutorizationhost=''
			where 
				( 
					(
						T.ctxbusiness>='33' and 
						T.ctxbusiness<='81'
					)
								
					or
								
					(
						T.ctxbusiness in ('88','89','90','91','92','93','94','95','96','97','98','A0','A1','A2','A3','A4','A5','A6')
					)
							
				) and

				T.ctxResultExt='00' and
				T.ctxType='20' and
				T.CtxStatus='0' and
				E.idconciliacion=@idconciliacion and 
				E.vconciliadored='N' and
				T.ftxCreateDate >= 
					convert(varchar,  
					dateadd(d,0, convert(datetime, vfechatransaccion)),112
				) and 
				
				T.ftxCreateDate <= 
					convert(varchar,  
					dateadd(d,5, convert(datetime, vfechatransaccion)),112
				) and 
				
				T.ctxSettleStatus='9'  and
				T.ntxAutorizationhost!=''
		end--Fin de if @vfechafinal < @fechadp1
			
		--Verificar Tabla de Log Produccción Actual para pago y comisión
		update E  with(rowlock)
		set	
			E.ipendiente=1
		from tb_detalle_transaccion_easy E  inner join  [192.168.3.28].dbheps2000.dbo.tptransactionlog T
		on
			ltrim(rtrim(E.vsecuencialunico))=ltrim(rtrim(T.ntxautorizationhost))   
		where 			
			( 
				(
					T.ctxbusiness>='33' and 
					T.ctxbusiness<='81'
				)
							
				or
							
				(
					T.ctxbusiness in ('88','89','90','91','92','93','94','95','96','97','98','A0','A1','A2','A3','A4','A5','A6')
				)
							
			) and
			
			T.ctxResultExt='00' and
			T.ctxType='20' and 
			T.CtxStatus='0' and
			E.idconciliacion=@idconciliacion and 
			E.vconciliadored='N' and
			T.ftxCreateDate >= 
			convert(varchar,  
				dateadd(d,0, convert(datetime, vfechatransaccion)),112
			) and 
			
			T.ftxCreateDate <= 
				convert(varchar,  
				dateadd(d,5, convert(datetime, vfechatransaccion)),112
			) and 
			
			T.ctxSettleStatus!='9' and
			T.ntxAutorizationhost!=''
		
		
		--Incluir los pagos y comisiones con BatchUpload
		update E  with(rowlock)
		set
			E.ipendiente=1	
		from tb_detalle_transaccion_easy E  inner join  [192.168.3.28].dbheps2000.dbo.tptransactionlog T
		on
			ltrim(rtrim(E.vsecuencialunico))=ltrim(rtrim(T.ntxautorizationhost))  
		inner join [192.168.3.28].dbheps2000.dbo.tptransactionlog B
		on
			T.ctxType=B.ctxType and
			T.ctxBatchid=B.ctxBatchid and
			T.ctxTxnNumber= B.ctxTxnNumber and
			T.ctxTerminalnum= B.ctxTerminalnum and
			T.ctxMerchantid= B.ctxMerchantid and
			B.CtxResultExt='00' and 
			B.ctxStatus='0' and
			B.CtxSettleStatus= '1'	
			and B.ntxAutorizationhost=''
		where 			
			( 
				(
					T.ctxbusiness>='33' and 
					T.ctxbusiness<='81'
				)
							
				or
							
				(
					T.ctxbusiness in ('88','89','90','91','92','93','94','95','96','97','98','A0','A1','A2','A3','A4','A5','A6')
				)
							
			) and

			
			T.ctxResultExt='00' and
			T.ctxType='20' and
			T.CtxStatus='0' and
			E.idconciliacion=@idconciliacion and 
			E.vconciliadored='N' and
			T.ftxCreateDate >= 
				convert(varchar,  
				dateadd(d,0, convert(datetime, vfechatransaccion)),112
			) and
			
			T.ftxCreateDate <= 
				convert(varchar,  
				dateadd(d,5, convert(datetime, vfechatransaccion)),112
			) and 
			 
			T.ctxSettleStatus='9'  and
			T.ntxAutorizationhost!=''

		--*****Buscar Registros Plataforma MIRED
		
		--Verificar los registros del Log Diario para Pago y comisión
		update E with(rowlock)
		set
			E.ipendiente=1
		from tb_detalle_transaccion_easy E  inner join  /*[192.168.3.32].*/DBDISTRIBUIDOR.dbo.TB_LOG_TRX_DIARIO  T
		on
			T.NUMERO_AUTORIZACION_HOST collate SQL_latin1_general_cp1_ci_as=E.vsecuencialunico 
		where
			T.FECHA_TRANSACCION  collate SQL_latin1_general_cp1_ci_as>= convert(varchar,  dateadd(d,1, convert(datetime, vfechatransaccion))  ,
											112) and
											
			T.FECHA_TRANSACCION collate SQL_latin1_general_cp1_ci_as <= convert(varchar,  dateadd(d,5, convert(datetime, vfechatransaccion)) ,
											112) and						
					
			T.tipo_transaccion='20' and
			T.respuesta='00' and
			
			( 
				(
					T.ID_PROVEEDOR>='33' and 
					T.ID_PROVEEDOR<='81'
				)
							
				or
							
				(
					T.ID_PROVEEDOR in ('88','89','90','91','92','93','94','95','96','97','98','A0','A1','A2','A3','A4','A5','A6')
				)
							
			) and
			
			T.estado='0' and
			E.idconciliacion=@idconciliacion and 
			E.vconciliadored='N' 
			
		--Verificar los registros en el log de producción para Pago y Comisión
		update E  with(rowlock)
		set 
			E.ipendiente=1
		from tb_detalle_transaccion_easy E  inner join /*[192.168.3.32].*/DBDISTRIBUIDOR.dbo.TB_LOG_TRX  T
		on
			T.NUMERO_AUTORIZACION_HOST collate SQL_latin1_general_cp1_ci_as=E.vsecuencialunico
		where
			T.FECHA_TRANSACCION  collate SQL_latin1_general_cp1_ci_as>= convert(varchar,  
													dateadd(d,1, convert(datetime, vfechatransaccion)),112
											) and
											
			T.FECHA_TRANSACCION collate SQL_latin1_general_cp1_ci_as <= convert(varchar,  dateadd(d,5, convert(datetime, vfechatransaccion)),
											112) and
											
			T.tipo_transaccion='20' and
			T.respuesta='00' and			
			( 
				(
					T.ID_PROVEEDOR>='33' and 
					T.ID_PROVEEDOR<='81'
				)
							
				or
							
				(
					T.ID_PROVEEDOR in ('88','89','90','91','92','93','94','95','96','97','98','A0','A1','A2','A3','A4','A5','A6')
				)
							
			) and
			
			T.estado='0' and
			E.idconciliacion=@idconciliacion and 
			E.vconciliadored='N'  
		
		--Poner a estado pendiente todos los registros de Pagos del Banco que consten en los movimientos de 
		--EasyCash y que no hayan sido conciliados por la red
		update B  with(rowlock) 
		set
			B.ipendiente=1
		from dbo.TB_DETALLE_TRANSACCION_BANCO B inner join tb_detalle_transaccion_easy E
		on
			B.idconciliacion= E.idconciliacion and
			B.ideasy= E.idtrxeasy 
		where
			E.ipendiente=1 and
			E.idconciliacion=@idconciliacion and
			E.vconciliadored='N' and
			E.vtipotransaccion='20' and
			B.vtipotransaccion='20'
		
		--********************Fin de Rutina de Regularización de Registros EasyCash***************************--
		
		--****************Rutina de Regularizacióbn de Registros del Banco de Pacífico************************--
		
		--***Búscar registros en la plataforma HIPER
		
		--Verificar en el Log Diario los Pagos
		update B  with(rowlock)
		set 
			B.ipendiente = 1
		from tb_detalle_transaccion_banco B inner join  [192.168.3.28].dbheps2000.dbo.tptransactionlog_diario T
		on
			T.ntxautorizationhost like + '%' + B.vreferencia 
		where
			( 
				(
					T.ctxbusiness>='33' and 
					T.ctxbusiness<='81'
				)
							
				or
							
				(
					T.ctxbusiness in ('88','89','90','91','92','93','94','95','96','97','98','A0','A1','A2','A3','A4','A5','A6')
				)
							
			) and
			
			T.ctxResultExt='00' and
			T.ctxType='20' and
			T.CtxStatus='0' and
			T.ftxCreateDate >= convert(varchar,  
										dateadd(d,0, convert(datetime, B.vfechacontable)),112) and
			T.ftxCreateDate <= convert(varchar,  
										dateadd(d,5, convert(datetime, B.vfechacontable)),112) and
			T.ctxSettleStatus!='9' and
			B.idconciliacion=@idconciliacion and 
			B.vconciliadored='N'  and
			T.ntxautorizationhost !=''
		
		--Verificar en el Log Diario Pagos BatchUpload
		update B  with(rowlock)
		set 
			B.ipendiente = 1
		from tb_detalle_transaccion_banco B inner join  [192.168.3.28].dbheps2000.dbo.tptransactionlog_diario T
		on
			T.ntxautorizationhost like + '%' + B.vreferencia 
			
		inner join [192.168.3.28].dbheps2000.dbo.tptransactionlog_diario A
		on
			A.cTxMerchantId= T.cTxMerchantId and
			A.cTxTerminalNum= T.cTxTerminalNum and
			A.ctxtype= T.ctxType and
			A.cTxTxnNumber= T.cTxTxnNumber and
			A.ctxBatchid= T.CtxBatchid and
			A.CtxResultExt= T.CtxResultExt and
			A.cTxStatus='0' and
			A.cTxSettleStatus='1' and
			A.ntxautorizationhost=''
		where			
			( 
				(
					T.ctxbusiness>='33' and 
					T.ctxbusiness<='81'
				)
							
				or
							
				(
					T.ctxbusiness in ('88','89','90','91','92','93','94','95','96','97','98','A0','A1','A2','A3','A4','A5','A6')
				)
							
			) and
			
			T.ctxResultExt='00' and
			T.ctxType='20' and
			T.CtxStatus='0' and
			T.ftxCreateDate >= convert(varchar,  
										dateadd(d,0, convert(datetime, B.vfechacontable)),112) and
			T.ftxCreateDate <= convert(varchar,  
										dateadd(d,5, convert(datetime, B.vfechacontable)),112) and
			T.ntxautorizationhost !='' and
			T.ctxSettleStatus='9' and
			B.idconciliacion=@idconciliacion and 
			B.vconciliadored='N'  
		
		
		--Verificar en el Log Diario Comisiones
		update B  with(rowlock)
		set 
			B.ipendiente = 1
		from tb_detalle_transaccion_banco B inner join  [192.168.3.28].dbheps2000.dbo.tptransactionlog_diario T
		on
			T.ntxautorizationhost like + '%' + B.vreferencia 
		where
			--T.ctxbusiness in('33','81')  and
			
			( 
				(
					T.ctxbusiness>='33' and 
					T.ctxbusiness<='81'
				)
							
				or
							
				(
					T.ctxbusiness in ('88','89','90','91','92','93','94','95','96','97','98','A0','A1','A2','A3','A4','A5','A6')
				)
							
			) and
			
			T.ctxResultExt='00' and
			T.ctxType='20' and
			T.CtxStatus='0' and
		
			T.ftxCreateDate >= convert(varchar,  
							dateadd(d,0, convert(datetime, B.vfechacontable)),112) and
			T.ftxCreateDate <= convert(varchar,  
							dateadd(d,5, convert(datetime, B.vfechacontable)),112) and
			T.ctxSettleStatus!='9' and
			B.idconciliacion=@idconciliacion and 
			B.vconciliadored='N'  and
			T.ntxautorizationhost2 !='' 
		
		--Verificar en el Log Diario Comisiones pero por BatchUpload
		update B  with(rowlock)
		set 
			B.ipendiente = 1
		from tb_detalle_transaccion_banco B inner join  [192.168.3.28].dbheps2000.dbo.tptransactionlog_diario T
		on
			B.vreferencia = T.ntxautorizationhost2
		inner join [192.168.3.28].dbheps2000.dbo.tptransactionlog_diario A
		on
			A.cTxMerchantId= T.cTxMerchantId and
			A.cTxTerminalNum= T.cTxTerminalNum and
			A.ctxtype= T.ctxType and
			A.cTxTxnNumber= T.cTxTxnNumber and
			A.ctxBatchid= T.CtxBatchid and
			A.CtxResultExt= T.CtxResultExt and
			A.cTxStatus='0' and
			A.cTxSettleStatus='1' and
			A.ntxautorizationhost=''							
		where
			--T.ctxbusiness in('33','81')  and
			
			( 
				(
					T.ctxbusiness>='33' and 
					T.ctxbusiness<='81'
				)
							
				or
							
				(
					T.ctxbusiness in ('88','89','90','91','92','93','94','95','96','97','98','A0','A1','A2','A3','A4','A5','A6')
				)
							
			) and
			
			T.ctxResultExt='00' and
			T.ctxType='20' and
			T.CtxStatus='0' and
		
			T.ftxCreateDate >= convert(varchar,  
							dateadd(d,0, convert(datetime, B.vfechacontable)),112) and
			T.ftxCreateDate <= convert(varchar,  
							dateadd(d,5, convert(datetime, B.vfechacontable)),112) and
			T.ctxSettleStatus='9' and
			B.idconciliacion=@idconciliacion and 
			B.vconciliadored='N'  and
			T.ntxautorizationhost2 !='' 

		if @vfechafinal < @fechadp1 --Ver fecha de Depuración para revisar Log Historico Total
		begin
			--Historico Total de pagos
			update B  with(rowlock)
			set 
				B.ipendiente =1
			from tb_detalle_transaccion_banco B inner join  /*[192.168.3.28].*/[DBHEPS2000_HIS].dbo.tpTransactionLog_his T
			on
				T.ntxautorizationhost like + '%' + B.vreferencia 
			where
				( 
					(
						T.ctxbusiness>='33' and 
						T.ctxbusiness<='81'
					)
							
					or
							
					(
						T.ctxbusiness in ('88','89','90','91','92','93','94','95','96','97','98','A0','A1','A2','A3','A4','A5','A6')
					)
							
				) and
			
				--T.ctxbusiness in('33','81')  and
				T.ctxResultExt='00' and
				T.ctxType='20' and
				T.CtxStatus='0' and
				T.ftxCreateDate >= convert(varchar,  
												dateadd(d,0, convert(datetime, B.vfechacontable)),112) and
				T.ftxCreateDate <= convert(varchar,  
				dateadd(d,5, convert(datetime, B.vfechacontable)),112) and

				T.ctxSettleStatus!='9' and
				B.idconciliacion=@idconciliacion and 
				B.vconciliadored='N'  and
				T.ntxautorizationhost !='' 
			
			--Historico Total de pagos batchUpload
			update B  with(rowlock)
			set 
				B.ipendiente =1
			from tb_detalle_transaccion_banco B inner join  [192.168.3.28].[DBHEPS2000_HIS].dbo.tpTransactionLog_his T
			on
				T.ntxautorizationhost like + '%' + B.vreferencia 
				
			inner join [192.168.3.28].[DBHEPS2000_HIS].dbo.tpTransactionLog_his A
			on
				A.cTxMerchantId= T.cTxMerchantId and
				A.cTxTerminalNum= T.cTxTerminalNum and
				A.ctxtype= T.ctxType and
				A.cTxTxnNumber= T.cTxTxnNumber and
				A.ctxBatchid= T.CtxBatchid and
				A.CtxResultExt= T.CtxResultExt and
				A.cTxStatus='0' and
				A.cTxSettleStatus='1' and
				A.ntxautorizationhost=''				
			where
				( 
					(
						T.ctxbusiness>='33' and 
						T.ctxbusiness<='81'
					)
								
					or
								
					(
						T.ctxbusiness in ('88','89','90','91','92','93','94','95','96','97','98','A0','A1','A2','A3','A4','A5','A6')
					)
							
				) and
				
				T.ctxResultExt='00' and
				T.ctxType='20' and
				T.CtxStatus='0' and
				T.ftxCreateDate >= convert(varchar,  
												dateadd(d,0, convert(datetime, B.vfechacontable)),112) and
				T.ftxCreateDate <= convert(varchar,  
									dateadd(d,5, convert(datetime, B.vfechacontable)),112) and
				
				T.ctxSettleStatus='9' and
				B.idconciliacion=@idconciliacion and 
				B.vconciliadored='N' and 
				T.ntxautorizationhost !='' 
			
			--Historico Total para Comisiones	
			update B  with(rowlock)
			set 
				B.ipendiente =1
			from tb_detalle_transaccion_banco B inner join /*[192.168.3.28].*/[DBHEPS2000_HIS].dbo.tpTransactionLog_his T
			on
				B.vreferencia = T.ntxautorizationhost2				
			where
				
				( 
					(
						T.ctxbusiness>='33' and 
						T.ctxbusiness<='81'
					)
								
					or
								
					(
						T.ctxbusiness in ('88','89','90','91','92','93','94','95','96','97','98','A0','A1','A2','A3','A4','A5','A6')
					)
							
				) and
				
				T.ctxResultExt='00' and
				T.ctxType='20' and
				T.CtxStatus='0' and
				T.ftxCreateDate >= convert(varchar,  
											dateadd(d,0, convert(datetime, B.vfechacontable)),112) and
				
				T.ftxCreateDate <= convert(varchar,  
											dateadd(d,5, convert(datetime, B.vfechacontable)),112) and
				T.ctxSettleStatus!='9' and
				B.idconciliacion=@idconciliacion and 
				B.vconciliadored='N' and
				T.ntxautorizationhost2 !='' 
				
			--Historico Total para Comisiones BatchUpload
			update B  with(rowlock)
			set 
				B.ipendiente =1
			from tb_detalle_transaccion_banco B inner join /*[192.168.3.28].*/[DBHEPS2000_HIS].dbo.tpTransactionLog_his T
			on
				B.vreferencia = T.ntxautorizationhost2
			
			inner join /*[192.168.3.28].*/[DBHEPS2000_HIS].dbo.tpTransactionLog_his A
			on
				A.cTxMerchantId= T.cTxMerchantId and
				A.cTxTerminalNum= T.cTxTerminalNum and
				A.ctxtype= T.ctxType and
				A.cTxTxnNumber= T.cTxTxnNumber and
				A.ctxBatchid= T.CtxBatchid and
				A.CtxResultExt= T.CtxResultExt and
				A.cTxStatus='0' and
				A.cTxSettleStatus='1' and
				A.ntxautorizationhost2=''						
			where
				( 
					(
						T.ctxbusiness>='33' and 
						T.ctxbusiness<='81'
					)
								
					or
								
					(
						T.ctxbusiness in ('88','89','90','91','92','93','94','95','96','97','98','A0','A1','A2','A3','A4','A5','A6')
					)
							
				) and
			
				T.ctxResultExt='00' and
				T.ctxType='20' and
				T.CtxStatus='0' and
				T.ftxCreateDate >= convert(varchar,  
											dateadd(d,0, convert(datetime, B.vfechacontable)),112) and
				T.ftxCreateDate <= convert(varchar,  
											dateadd(d,5, convert(datetime, B.vfechacontable)),112) and
				T.ctxSettleStatus='9' and
				B.idconciliacion=@idconciliacion and 
				B.vconciliadored='N' and
				T.ntxautorizationhost2 !='' 

		end
		
		--Verificar en el Log Produccción para los pagos
		update B  with(rowlock)
		set 
			B.ipendiente =1
		from tb_detalle_transaccion_banco B inner join  [192.168.3.28].dbheps2000.dbo.tptransactionlog T
		on
			T.ntxautorizationhost like + '%' + B.vreferencia 
		where
			
			( 
				(
					T.ctxbusiness>='33' and 
					T.ctxbusiness<='81'
				)
							
				or
							
				(
					T.ctxbusiness in ('88','89','90','91','92','93','94','95','96','97','98','A0','A1','A2','A3','A4','A5','A6')
				)
							
			) and
			
			T.ctxResultExt='00' and
			T.ctxType='20' and
			T.CtxStatus='0' and
			T.ftxCreateDate >= convert(varchar,  
								dateadd(d,0, convert(datetime, B.vfechacontable)),112) and
			T.ftxCreateDate <= convert(varchar,  
			dateadd(d,1, convert(datetime, B.vfechacontable)),112) and
			T.ctxSettleStatus!='9' and
			B.idconciliacion=@idconciliacion and 
			B.vconciliadored='N' and
			T.ntxautorizationhost !='' 
		
		--Verificar en el Log Producción para los pagos BatchUpload
		update B  with(rowlock)
		set 
			B.ipendiente = 1
		from tb_detalle_transaccion_banco B inner join  [192.168.3.28].dbheps2000.dbo.tptransactionlog T
		on
			T.ntxautorizationhost like + '%' + B.vreferencia 
		inner join [192.168.3.28].dbheps2000.dbo.tptransactionlog A
		on
			A.cTxMerchantId= T.cTxMerchantId and
			A.cTxTerminalNum= T.cTxTerminalNum and
			A.ctxtype= T.ctxType and
			A.cTxTxnNumber= T.cTxTxnNumber and
			A.ctxBatchid= T.CtxBatchid and
			A.CtxResultExt= T.CtxResultExt and
			A.cTxStatus='0' and
			A.cTxSettleStatus='1' and
			A.ntxautorizationhost=''
		where
			( 
				(
					T.ctxbusiness>='33' and 
					T.ctxbusiness<='81'
				)
							
				or
							
				(
					T.ctxbusiness in ('88','89','90','91','92','93','94','95','96','97','98','A0','A1','A2','A3','A4','A5','A6')
				)
							
			) and
			
			T.ctxResultExt='00' and
			T.ctxType='20' and
			T.CtxStatus='0' and
			T.ftxCreateDate >= convert(varchar,  
										dateadd(d,0, convert(datetime, B.vfechacontable)),112) and
										
			T.ftxCreateDate <= convert(varchar,  
										dateadd(d,5, convert(datetime, B.vfechacontable)),112) and			
							
			T.ctxSettleStatus='9' and
			B.idconciliacion=@idconciliacion and 
			B.vconciliadored='N'  and
			T.ntxautorizationhost !='' 
		
		--Verificar el log de producción para las Comisiones
		update B  with(rowlock)
		set 
			B.ipendiente = 1
		from tb_detalle_transaccion_banco B inner join  [192.168.3.28].dbheps2000.dbo.tptransactionlog T
		on
			B.vreferencia = T.ntxautorizationhost2
								
		where
			
			( 
				(
					T.ctxbusiness>='33' and 
					T.ctxbusiness<='81'
				)
							
				or
							
				(
					T.ctxbusiness in ('88','89','90','91','92','93','94','95','96','97','98','A0','A1','A2','A3','A4','A5','A6')
				)
							
			) and
			
			T.ctxResultExt='00' and
			T.ctxType='20' and
			T.CtxStatus='0' and
			T.ftxCreateDate >= convert(varchar,  
											dateadd(d,0, convert(datetime, B.vfechacontable)),112
										) and
										
			T.ftxCreateDate <= convert(varchar,  
											dateadd(d,5, convert(datetime, B.vfechacontable)),112
										) and
			T.ctxSettleStatus!='9' and
			B.idconciliacion=@idconciliacion and 
			B.vconciliadored='N' and
			T.ntxautorizationhost2 !='' 
		
		--Verificar el log de Producción para las comisiones BatchUpload
		update B  with(rowlock)
		set 
			B.ipendiente = 1
		from tb_detalle_transaccion_banco B inner join  [192.168.3.28].dbheps2000.dbo.tptransactionlog T
		on
			B.vreferencia = T.ntxautorizationhost2
		inner join [192.168.3.28].dbheps2000.dbo.tptransactionlog A
		on
			A.cTxMerchantId= T.cTxMerchantId and
			A.cTxTerminalNum= T.cTxTerminalNum and
			A.ctxtype= T.ctxType and
			A.cTxTxnNumber= T.cTxTxnNumber and
			A.ctxBatchid= T.CtxBatchid and
			A.CtxResultExt= T.CtxResultExt and
			A.cTxStatus='0' and
			A.cTxSettleStatus='1' and
			A.ntxautorizationhost2=''							
		where
			
			( 
				(
					T.ctxbusiness>='33' and 
					T.ctxbusiness<='81'
				)
							
				or
							
				(
					T.ctxbusiness in ('88','89','90','91','92','93','94','95','96','97','98','A0','A1','A2','A3','A4','A5','A6')
				)
							
			) and
			
			T.ctxResultExt='00' and
			T.ctxType='20' and
			T.CtxStatus='0' and
		
			T.ftxCreateDate >= convert(varchar,  
							dateadd(d,0, convert(datetime, B.vfechacontable)),112) and
							
			T.ftxCreateDate <= convert(varchar,  
							dateadd(d,0, convert(datetime, B.vfechacontable)),112) and
			T.ctxSettleStatus='9' and
			B.idconciliacion=@idconciliacion and 
			B.vconciliadored='N'  and
			T.ntxautorizationhost2 !='' 
		
		--*******Buscar los registros en la plataforma MIRED
		
		--Verificar el log diario para pagos log diario
		update B  with(rowlock)
		set
			B.ipendiente=	1
		from tb_detalle_transaccion_banco B  inner join  /*[192.168.3.32].*/DBDISTRIBUIDOR.DBO.TB_LOG_TRX_DIARIO  T
		on
			'2' + B.vreferencia=T.NUMERO_AUTORIZACION_HOST  collate SQL_latin1_general_cp1_ci_as
		where
			T.FECHA_TRANSACCION  collate SQL_latin1_general_cp1_ci_as >= convert(varchar,  
											dateadd(d,1, convert(datetime, B.vfechacontable)),112
											) and
											
			T.FECHA_TRANSACCION  collate SQL_latin1_general_cp1_ci_as <= convert(varchar,  
											dateadd(d,5, convert(datetime, B.vfechacontable)),112
			) and
			
			T.tipo_transaccion='20' and
			T.respuesta='00' and
			
			( 
				(
					T.ID_PROVEEDOR>='33' and 
					T.ID_PROVEEDOR<='81'
				)
							
				or
							
				(
					T.ID_PROVEEDOR in ('88','89','90','91','92','93','94','95','96','97','98','A0','A1','A2','A3','A4','A5','A6')
				)
							
			) and
			
			T.estado='0' and
			B.idconciliacion=@idconciliacion  and 
			B.vconciliadored='N' and
			T.NUMERO_AUTORIZACION_HOST!=''
	
		--Verifcar el log diario para Comisiones log diario
		update B  with(rowlock)
		set
			B.ipendiente=	1
		from tb_detalle_transaccion_banco B  inner join   /*[192.168.3.32].*/DBDISTRIBUIDOR.DBO.TB_LOG_TRX_DIARIO  T
		on
			T.NUMERO_AUTORIZACION_HOST1  collate SQL_latin1_general_cp1_ci_as= B.vreferencia
		where
			T.FECHA_TRANSACCION  collate SQL_latin1_general_cp1_ci_as >= convert(varchar,  
													dateadd(d,1, convert(datetime, B.vfechacontable)),112
											) and
											
			T.FECHA_TRANSACCION  collate SQL_latin1_general_cp1_ci_as <= convert(varchar,  dateadd(d,5, convert(datetime, B.vfechacontable)),
											112) and	
											
			T.tipo_transaccion='20' and
			T.respuesta='00' and			
			( 
				(
					T.ID_PROVEEDOR>='33' and 
					T.ID_PROVEEDOR<='81'
				)
							
				or
							
				(
					T.ID_PROVEEDOR in ('88','89','90','91','92','93','94','95','96','97','98','A0','A1','A2','A3','A4','A5','A6')
				)
							
			) and
			
			T.estado='0' and
			B.idconciliacion=@idconciliacion  and 
			B.vconciliadored='N'   and
			T.NUMERO_AUTORIZACION_HOST1!=''
	
		--Verificar el log de producción para los pagos
		update B  with(rowlock)
		set
			B.ipendiente=	1
		from tb_detalle_transaccion_banco B  inner join  /*[192.168.3.32].*/DBDISTRIBUIDOR.DBO.TB_LOG_TRX  T
		on
			'2' + B.vreferencia=T.NUMERO_AUTORIZACION_HOST collate SQL_latin1_general_cp1_ci_as
		where
			T.FECHA_TRANSACCION collate SQL_latin1_general_cp1_ci_as >= convert(varchar,  
											dateadd(d,1, convert(datetime, B.vfechacontable)),112
											) and
											
			T.FECHA_TRANSACCION collate SQL_latin1_general_cp1_ci_as <= convert(varchar,  
											dateadd(d,5, convert(datetime, B.vfechacontable)),112
			) and
			
			T.tipo_transaccion='20' and
			T.respuesta='00' and			
			( 
				(
					T.ID_PROVEEDOR>='33' and 
					T.ID_PROVEEDOR<='81'
				)
							
				or
							
				(
					T.ID_PROVEEDOR in ('88','89','90','91','92','93','94','95','96','97','98','A0','A1','A2','A3','A4','A5','A6')
				)
							
			) and
			
			T.estado='0' and
			B.idconciliacion=@idconciliacion  and 
			B.vconciliadored='N' and
			T.NUMERO_AUTORIZACION_HOST!=''
	
	
		--Verificar el log de Producción para la comisión
		update B  with(rowlock)
		set
			B.ipendiente=	1
		from tb_detalle_transaccion_banco B  inner join   /*[192.168.3.32].*/DBDISTRIBUIDOR.DBO.TB_LOG_TRX  T
		on
			T.NUMERO_AUTORIZACION_HOST1 collate SQL_latin1_general_cp1_ci_as = B.vreferencia
		where
			T.FECHA_TRANSACCION collate SQL_latin1_general_cp1_ci_as >= convert(varchar,  
													dateadd(d,1, convert(datetime, B.vfechacontable)),112
											) and
											
			T.FECHA_TRANSACCION collate SQL_latin1_general_cp1_ci_as<= convert(varchar,  dateadd(d,5, convert(datetime, B.vfechacontable)),
											112) and	
			T.tipo_transaccion='20' and
			T.respuesta='00' and			
			( 
				(
					T.ID_PROVEEDOR>='33' and 
					T.ID_PROVEEDOR<='81'
				)
							
				or
							
				(
					T.ID_PROVEEDOR in ('88','89','90','91','92','93','94','95','96','97','98','A0','A1','A2','A3','A4','A5','A6')
				)
							
			) and
			
			T.estado='0' and
			B.idconciliacion=@idconciliacion  and 
			B.vconciliadored='N'  and
			T.NUMERO_AUTORIZACION_HOST1!=''
		--************Fin de Rutina de Regularización de Registros del Banco del Pacifico*********************--
		
		update TB_CONCILIACION_SERVICIO  with(rowlock)
		set 
			vfechaconciliacion=@vfechaconciliacion,
			vhoraconciliacion=@vhoraconciliacion,
			icantidadtrxred=@cantidadtrx,
			iestadoconciliacion=@iestado_conciliacion,
			vconciliadoeasyred=@vconciliadoeasyred,
			vconciliadobancored=@vconciliadobancored,
			vconciliadoeasybanco=@vconciliadoeasybanco
		where
			idconciliacion=@idconciliacion
	
	end--Fin de if(@opcion=0)
	
	if (@opcion=1)
	begin
		set @iestado_conciliacion=2
		set @dfechasistema= getdate()
	
		insert into [DBREPORTS].[dbo].[HIP_RECAUDACION] (idgroup,idchain,idmerchant,idbank,
		amount_deposited,date_time,reference,autorization_date_time,descGroup,descChain,
		descMerchant,descBank, id_cuenta_banco,siga_fecdeposito,num_recibo,FECHA_DEPOSITO_TEXTO,
		siga_marca,siga_detalle,siga_empresa,siga_sujetadeclaracion,feccrea,                
        tipo_forma_pago,refeValida,id_proveedor,idbanktran,Usuario_Validacion,id_pr_pago,
        tipocli,id_cliente_distribuidor,id_cliente_distribuidor_padre,ORIGENPAGO,
        fechaEasyCash,fechaContableBPac) 
		select 
			b.id_grupo,
			b.id_cadena,
			b.id,
			c.id_banco,
			--e.valor amount_deposited,              
			e.nvalor amount_deposited,
			'date_time'=	substring(fTxCreateDate,1,4)+'-'+substring(fTxCreateDate,5,2)+
							'-'+substring(fTxCreateDate,7,2)+' '+
							substring(hTxCreateTime,1,2)+':'+ 
							substring(hTxCreateTime,3,2)+':'+
							substring(hTxCreateTime,5,2)+'.000',                  
			a.ntxgencounter reference,
			        
			'autorization_date_time'=	substring(fTxCreateDate,1,4)+'-'+substring(fTxCreateDate,5,2)+
										'-'+substring(fTxCreateDate,7,2)+' '+
										substring(hTxCreateTime,1,2)+':'+
										substring(hTxCreateTime,3,2)+':'+
										substring(hTxCreateTime,5,2)+'.000',                  
			(
				select descripcion from dbheps2000..tb_grupo 
				where 
					id=b.id_grupo
			) descGroup,
			(
				select descripcion from dbheps2000..tb_cadena 
				where 
					id=b.id_cadena
			) descCadena,            
			
		
			case cTxIdMedio
				when '0' then b.descripcion 
				when '5' then DIST.nombre_comercial
			end  descMerchant,
			
			d.descripcion descBanco,
			c.id id_cuenta_banco,
			fTxAccountingDate siga_fecdeposito,              
			e.vreferencia num_recibo,
			a.fTxCreateDate FECHA_DEPOSITO_TEXTO,
			
			'S' siga_marca,
			
			case  a.ctxbusiness
				when '33' then  'CLARO $1 - ' +  ntxautorizationhostBPAC + ' - ' + cTxTelefhoneNumber  
				else e.vconcepto
			end siga_detalle,
			
			'BNET' siga_empresa,
			'S' siga_sujetadeclaracion,
			@dfechasistema feccrea,
			'EF' tipo_forma_pago,
			'S' refeValida,                
			(select id_proveedor_facturacion from dbheps2000..tb_proveedor where id_proveedor=cTxBusiness),
			95 idbanktran,
			'SISTEMA' Usuario_Validacion,
			a.ntxgencounter id_pr_pago,
			convert(tinyint,a.cTxIdMedio) tipocli,
			
			a.id_cliente_distribuidor,
			a.id_cliente_distribuidor_padre,
			case a.ctxBusiness	
				when '72' then 54 --Si es un Bono
				else 50 end ORIGENPAGO,
			FechaEasyCash,
			e.vfechaContable fechaContableBPac
		from tptransactionlog a    inner JOIN TB_DETALLE_TRANSACCION_BANCO e /*dbconciliacion..DetConciliacionBPAC e*/ 
		on 
			(
				ntxautorizationhostBPAC=e.vreferencia or 
				a.ntxautorizationhost2=e.vreferencia
			) and 
			e.idconciliacion= /*@idcab*/ @idconciliacion and 
			e.vconciliadored='S'

		left join dbheps2000..tb_comercio b 
		on 
			a.ctxmerchantid=b.codigo_merchant and 
			a.cTxIdMedio='0'                 

		inner join dbreports..hip_cuenta_banco c 
		on 
			c.id_banco=2 and 
			c.estado=1                  

		inner join dbreports..HIP_banco d 
		on 
			d.id=2 and 
			d.estado=1                  
		
		left join DBDISTRIBUIDOR.DBO.TB_CLIENTE_DISTRIBUIDOR DIST
		on
			--DIST.id= isnull([ContBroadnet].[dbo].[fn_idpadrepri_mired](a.id_cliente_distribuidor),a.id_cliente_distribuidor) and
			DIST.id=a.id_cliente_distribuidor_padre and
			a.cTxIdMedio='5'
		
		where 
			a.id_cabecera=/*@idcab*/  @idconciliacion and 
			a.conciliado='S' and 
			a.Conciliado2='S' and 
			
			( 
				(
					ctxbusiness>='33' and 
					ctxbusiness<='81'
				)
							
				or
							
				(
					ctxbusiness in ('88','89','90','91','92','93','94','95','96','97','98','A0','A1','A2','A3','A4','A5','A6')
				)
							
			) and
			
			
			not exists(
							select 1 from DBREPORTS..HIP_RECAUDACION x 
							where 
								id_proveedor=(select a.id_proveedor_facturacion from dbheps2000..tb_proveedor a where a.id_proveedor=ctxbusiness) and 
								(
									ntxautorizationhostBPAC=x.num_recibo or 
									a.ntxautorizationhost2=x.num_recibo
								) and
								x.siga_fecdeposito= a.fTxAccountingDate
			)  
		
		
		update TB_CONCILIACION_SERVICIO  with(rowlock)
		set 
			vfechaenvioconciliacion=@vfechaconciliacion,
			vhoraenvioconciliacion=@vhoraconciliacion,
			iestadoconciliacion =@iestado_conciliacion
		where
			idconciliacion=@idconciliacion	
	end--Fin de if (@opcion=1)


	if (@opcion=2) --Envío de los registros conciliados y no conciliados a un repositorio de trabajo
	begin
		--Escenario 1: Ingreso de las recaudaciones y comisiones conciliadas (CONCILIADAS Y ENVIADA A RECUADACION)
		insert into [DBREPORTS].[dbo].[HIP_RECAUDACION_SERVICIO] (
		vfechatransaccion,vreferenciapago,vidproveedor,vconcepto,
		nvalorpago,vreferenciacomision,ntotalcomision,idconciliacion,
		vconciliadored,vconciliadobanco,vconciliadoeasy,vestadodescuadre,vsecuencialunico)
		select 
			TP.ftxcreatedate fecha,
			A.vreferencia referenciapago ,
			A.vidproveedor,
			case A.vidproveedor 
				when '33' then 'Recaud. Claro $1'
				else A.vconcepto
			end vconcepto ,
			A.nvalor pago,
			B.vreferencia vreferenciacomision,
	
			case A.vidproveedor
				when '33' then 0.05
				else  sum( isnull(B.nvalor,0)) 
			end Totalcomision,
			A.idconciliacion,
			'S' vconciliadored,
			'S' vconciliadobanco,
			'S' vconciliadoeasy,
			'CONCILIADO' vestadodescuadre,
			TP.ntxAutorizationhost
		from tb_detalle_transaccion_banco A  inner join tptransactionlog TP
		on
			TP.ntxautorizationhostBPAC=A.vreferencia and
			TP.id_cabecera= A.idconciliacion and
			TP.conciliado='S' and 
			TP.conciliado2='S'
		left join tb_detalle_transaccion_banco B 
		on
			A.idconciliacion= B.idconciliacion and
			A.vreferencia= B.vreferencia2 and
			B.vnumero!='1613' and
			B.vtipotransaccion !='20' and
			B.ipendiente=0 and 
			B.vvalida!='S'
		where
			A.vconciliadored='S' and
			A.idconciliacion=@idconciliacion and
			A.vconciliadoeasy='S' and
			A.vtipotransaccion='20' and
			A.vvalida!='S' and
			A.ipendiente=0  
		group by 
			TP.ftxcreatedate,A.vreferencia, 
			A.vidproveedor, A.nvalor, 
			B.vreferencia,A.idconciliacion,
			A.vconcepto, TP.ntxAutorizationhost
		order by TP.ftxcreatedate, A.idconciliacion, A.vreferencia
		
		
		--Esnecerario 2: Ingreso de Transacciones que solo esta en la Red (SOBRANTES)
		insert into [DBREPORTS].[dbo].[HIP_RECAUDACION_SERVICIO] (
		vfechatransaccion,vreferenciapago,vidproveedor,vconcepto,
		nvalorpago,vreferenciacomision,ntotalcomision,idconciliacion,
		vconciliadored,vconciliadobanco,vconciliadoeasy,vestadodescuadre,vsecuencialunico)
		select 
			ftxCreateDate,
			ntxAutorizationHost vreferenciapago,
			cTxBusiness vidproveedor,
			case cTxBusiness
				when '33' then 'Reacud. Claro $1'
				else 'Recaud. Servicios'
			end vconcepto,
			nTxAmount,
			ntxAutorizationHost2 vreferenciacomion,
			0 totalcomision,
			id_cabecera idconciliacion,
			'S' vconciliadored,
			'N' vconciliadobanco,
			'N' vconciliadoeasy,
			'SOBRANTE' vestadodescuadre,
			NtxAutorizationhost
		from tptransactionlog  
		where
			id_cabecera =@idconciliacion and
			conciliado='N' and 
			conciliado2='N' and 
			estado=0 and 
			ntxAutorizationhost!='00000000' and 
			rtrim(ltrim(ntxAutorizationhost))!=''
		order by ftxCreatedate, ntxAutorizationHost,id_cabecera
		
		--Escenario 3: Transacciones que estan en la red y puntomatico y no en el banco (SOBRANTES)
		insert into [DBREPORTS].[dbo].[HIP_RECAUDACION_SERVICIO] (
		vfechatransaccion,vreferenciapago,vidproveedor,vconcepto,
		nvalorpago,vreferenciacomision,ntotalcomision,idconciliacion,
		vconciliadored,vconciliadobanco,vconciliadoeasy,vestadodescuadre,vsecuencialunico) 
		select 
			TP.ftxcreatedate vfechatransaccion,
			A.vsecuencialunico vreferenciapago,
			A.vidproveedor,
		
			case A.vidproveedor
				when '33' then 'Reacud. Claro $1'
				else A.vdescripcionservicio
			end vdescripcionservicio,
			
			A.nvalor valorpago,
			B.vsecuencialunicobanco2 vreferenciacomision,
			
			case A.vidproveedor 
				when '33' then 0.05
				else  isnull( B.nvalor,0) 
			end valorcomision,
			A.idconciliacion,
			'S' vconciliadored,
			'N' vconciliadobanco,
			'S' vconciliadoeasy,
			'SOBRANTE' vestadodescuadre,
			TP.NtxAutorizationhost
		from tb_detalle_transaccion_easy A  inner join tptransactionlog TP
		on
			A.idconciliacion= TP.id_cabecera and
			A.vsecuencialunicobanco=TP.ntxautorizationhostBPAC

		left join tb_detalle_transaccion_easy B
		on
			A.idconciliacion=B.idconciliacion and
			A.vsecuencialunico= B.vsecuencialunico and
			B.vtipotransaccion='00' 
		where
			A.ipendiente=0 and
			A.vconciliadored='S' and
			A.vconciliadobanco='N' and
			A.vtipotransaccion='20' and
			TP.conciliado='S' and 
			TP.conciliado2='N' and 
			A.idconciliacion =@idconciliacion
		order by TP.ftxcreatedate, A.idconciliacion, A.vsecuencialunico

		
		--Escenario 4: Transacciones que estan en la red y el banco y no esta en Puntomatico (SOBRANTES)
		insert into [DBREPORTS].[dbo].[HIP_RECAUDACION_SERVICIO] (
		vfechatransaccion,vreferenciapago,vidproveedor,vconcepto,
		nvalorpago,vreferenciacomision,ntotalcomision,idconciliacion,
		vconciliadored,vconciliadobanco,vconciliadoeasy,vestadodescuadre,vsecuencialunico) 
		select 
			TP.ftxcreatedate fecha,
			A.vreferencia referenciapago ,
			A.vidproveedor,
			case A.vidproveedor
				when '33' then 'Reacud. Claro $1'
				else A.vconcepto
			end vconcepto,
			A.nvalor pago,
			B.vreferencia vreferenciacomision,
			
			case A.vidproveedor
				when '33' then 0.05
				else  sum( isnull(B.nvalor,0)) 
			end Totalcomision,
			A.idconciliacion,
			'S' vconciliadored,
			'S' vconciliadobanco,
			'N' vconciliadoeasy,
			'SOBRANTE' vestadodescuadre,
			TP.NtxAutorizationhost
		from tb_detalle_transaccion_banco A  inner join tptransactionlog TP
		on
			TP.ntxautorizationhostBPAC=A.vreferencia and
			TP.id_cabecera= A.idconciliacion and
			TP.conciliado='N' and 
			TP.conciliado2='S'
		left join tb_detalle_transaccion_banco B 
		on
			A.idconciliacion= B.idconciliacion and
			A.vreferencia= B.vreferencia2 and
			B.vnumero!='1613' and
			B.vtipotransaccion !='20' and
			B.ipendiente=0 and B.vvalida!='S'
		where
			A.vconciliadored='S' and
			A.idconciliacion=@idconciliacion and
			A.vconciliadoeasy='N' and
			A.vtipotransaccion='20' and
			A.vvalida!='S' and
			A.ipendiente=0 
		group by 
			TP.ftxcreatedate,
			A.vreferencia, 
			A.vidproveedor, 
			A.nvalor, 
			B.vreferencia,
			A.idconciliacion,
			A.vconcepto,
			TP.ntxAutorizationhost
		order by TP.ftxcreatedate, A.idconciliacion, A.vreferencia
		
		--Comisiones (Sin Pago) que estan en el banco y la red y no esta en Puntomatico (SOBRANTES)
		insert into [DBREPORTS].[dbo].[HIP_RECAUDACION_SERVICIO] (
		vfechatransaccion,vreferenciapago,vidproveedor,vconcepto,
		nvalorpago,vreferenciacomision,ntotalcomision,idconciliacion,
		vconciliadored,vconciliadobanco,vconciliadoeasy,vestadodescuadre,vsecuencialunico) 
		select  
			TP.ftxcreatedate fecha,
			B.vreferencia as refpago,
			A.vidproveedor,
						
			case A.vidproveedor
				when '33' then 'Reacud. Claro $1'
				else isnull(A.vconcepto,'Reacaud. Servicios')
			end vconcepto,
			B.nvalor pago,
			A.vreferencia refcomision,
			
			case A.vidproveedor
				when '33' then 0.05
				else  sum( isnull(A.nvalor,0)) 
			end Totalcomision,
			A.idconciliacion,
			'S' vconciliadored,
			'S' vconciliadobanco,
			'N' vconciliadoeasy,
			'SOBRANTE' vestadodescuadre,
			TP.NtxAutorizationhost
		from tb_detalle_transaccion_banco A inner join tptransactionlog TP
		on
			TP.id_cabecera=A.idconciliacion and
			TP.conciliado='N' and 
			TP.conciliado2='S' and
			TP.ntxAutorizationHost2= A.vreferencia 
		left join tb_detalle_transaccion_banco B
		on
			A.idconciliacion= B.idconciliacion and
			B.vtipotransaccion='20' and
			A.vreferencia2= B.vreferencia and
			A.ipendiente=0 and A.vvalida!='S'
		where
			A.vtipotransaccion !='20' and
			A.idconciliacion =@idconciliacion  and
			A.vnumero!='1613' and
			A.vconciliadored='S' and 
			A.vconciliadoeasy='N' and
			A.vvalida!='S' and 
			B.nvalor is null
			
		group by
			TP.ftxcreatedate,
			B.nvalor,
			A.vreferencia,
			B.vreferencia,
			A.vidproveedor,
			A.vconcepto,
			A.idconciliacion,
			TP.NtxAutorizationHost
		order by 
			TP.ftxcreatedate,A.idconciliacion, B.vreferencia,A.vreferencia
	
		--Escenario 5: Ingreso de recaudaciones que solo estan en Puntomatico (FALTANTES)
		insert into [DBREPORTS].[dbo].[HIP_RECAUDACION_SERVICIO] (
		vfechatransaccion,vreferenciapago,vidproveedor,vconcepto,
		nvalorpago,vreferenciacomision,ntotalcomision,idconciliacion,
		vconciliadored,vconciliadobanco,vconciliadoeasy,vestadodescuadre,vsecuencialunico)
		select 
			A.vfechatransaccion,
			A.vsecuencialunico vreferenciapago,
			B.vidproveedor,
			
			case B.vidproveedor 
				when '33' then 'Reacud. Claro $1'
				else A.vdescripcionservicio
			end vdescripcionservicio,
			
			A.nvalorpre pago ,
			null vreferenciacomision, 
			A.nvalorcomision TotalComision,
			A.idconciliacion,
			'N' vconciliadored,
			'N' vconciliadobanco,
			'S' vconciliadoeasy,
			'FALTANTE' vestadodescuadre,
			A.vsecuencialunico
		from tb_transaccion_easy A inner join  tb_detalle_transaccion_easy B
		on
			A.idtrx=B.idtrxeasy and
			A.idconciliacion=B.idconciliacion 
		where
			B.vconciliadobanco='N' and
			B.vconciliadored ='N' and
			A.idconciliacion =@idconciliacion and 
			B.vtipotransaccion='20' and
			B.ipendiente=0
		order by A.vfechatransaccion,A.idconciliacion,A.vsecuencialunico,A.idtrx
		
		
		--Escenario 6: Obtener los pagos que estan en el Banco y Puntomatico y no en la RED (FALTANTES)
		insert into [DBREPORTS].[dbo].[HIP_RECAUDACION_SERVICIO] (
		vfechatransaccion,vreferenciapago,vidproveedor,vconcepto,
		nvalorpago,vreferenciacomision,ntotalcomision,idconciliacion,
		vconciliadored,vconciliadobanco,vconciliadoeasy,vestadodescuadre,vsecuencialunico)
		select 
			E.vfechatransaccion,
			A.vreferencia referenciapago,
			A.vidproveedor,
			
			case A.vidproveedor 
				when '33' then 'Reacud. Claro $1'
				else A.vconcepto
			end vconcepto,
			
			A.nvalor  pago,
			B.vreferencia  referenciacomision,  

			case A.vidproveedor
				when '33' then 0.05
				else  sum( isnull(B.nvalor,0)) 
			end Totalcomision,
			A.idconciliacion,
			'N' vconciliadored,
			'S' vconciliadobanco,
			'S' vconciliadoeasy,
			'FALTANTE' vestadodescuadre,
			E.vsecuencialunico
		from tb_detalle_transaccion_BANCO A inner join dbo.TB_DETALLE_TRANSACCION_EASY E
		on
			A.idconciliacion= E.idconciliacion and 
			A.vtipotransaccion= E.vtipotransaccion and
			E.ipendiente=0 and 
			E.vconciliadored='N' and
			E.vconciliadobanco='S' and
			E.idtrxeasy= A.ideasy
		left join tb_detalle_transaccion_BANCO B
		on
			 substring(A.vreferencia,2,len(A.vreferencia)-1)= substring(B.vreferencia,2,len(B.vreferencia)-1)  and
			 B.vtipotransaccion!='20'  and 
			 B.vnumero!='1613' and 
			 B.ipendiente=0 and B.vvalida!='S' and
			 A.vfechacontable=B.vfechacontable and
			 A.idconciliacion=B.idconciliacion
		where
			A.vconciliadored='N' and
			A.vconciliadoeasy ='S' and
			A.idconciliacion =@idconciliacion and
			A.vvalida!='S'  and 
			A.ipendiente=0 and
			A.vtipotransaccion='20' 
		group by 
			E.vfechatransaccion,
			A.vreferencia, A.vidproveedor, 
			A.nvalor, B.nvalor, B.vreferencia,A.idconciliacion,A.vconcepto,
			E.vsecuencialunico
		order by E.vfechatransaccion, A.idconciliacion, A.vreferencia
		
		
		--Escenario 7: Obtener los pagos  del lado del banco (FALTANTES)
		insert into [DBREPORTS].[dbo].[HIP_RECAUDACION_SERVICIO] (
		vfechatransaccion,vreferenciapago,vidproveedor,vconcepto,
		nvalorpago,vreferenciacomision,ntotalcomision,idconciliacion,
		vconciliadored,vconciliadobanco,vconciliadoeasy,vestadodescuadre,vsecuencialunico)
		select 
			A.vfechacontable,
			A.vreferencia referenciapago,
			A.vidproveedor,
			
			case A.vidproveedor 
				when '33' then 'Reacud. Claro $1'
				else A.vconcepto
			end vconcepto,
			
			A.nvalor  pago,
			B.vreferencia  referenciacomision,  

			case A.vidproveedor
				when '33' then 0.05
				else  sum( isnull(B.nvalor,0)) 
			end Totalcomision,
			
			A.idconciliacion,
			'N' vconciliadored,
			'S' vconciliadobanco,
			'N' vconciliadoeasy,
			'FALTANTE' vestadodescuadre,
			case 
				when len(A.vreferencia) < 8 then '2' +  replicate( '0',7 - len(rtrim(ltrim(A.vreferencia)))) + rtrim(ltrim(A.vreferencia))
				else A.vreferencia
			end
		from tb_detalle_transaccion_BANCO A left join tb_detalle_transaccion_BANCO B
		on
			 substring(A.vreferencia,2,len(A.vreferencia)-1)= substring(B.vreferencia,2,len(B.vreferencia)-1)  and
			 B.vtipotransaccion!='20'  and 
			 B.vnumero!='1613' and 
			 B.ipendiente=0 and B.vvalida!='S' and
			 A.vfechacontable=B.vfechacontable and
			 A.idconciliacion=B.idconciliacion
		where
			A.vconciliadored='N' and
			A.vconciliadoeasy ='N' and
			A.idconciliacion =@idconciliacion and
			A.vvalida!='S'  and 
			A.ipendiente=0 and
			A.vtipotransaccion='20' 
		group by 
			A.vfechacontable,
			A.vreferencia, A.vidproveedor, 
			A.nvalor, B.nvalor, B.vreferencia,A.idconciliacion,A.vconcepto
		order by A.vfechacontable, A.idconciliacion, A.vreferencia
		
		
		--Obtener las comisiones (Sin Pago) del lado del banco (FALTANTES)
		insert into [DBREPORTS].[dbo].[HIP_RECAUDACION_SERVICIO] (
		vfechatransaccion,vreferenciapago,vidproveedor,vconcepto,
		nvalorpago,vreferenciacomision,ntotalcomision,idconciliacion,
		vconciliadored,vconciliadobanco,vconciliadoeasy,vestadodescuadre,vsecuencialunico)
		select
			A.vfechacontable,
			B.vreferencia as vreferenciapago,
			A.vidproveedor,
			
			case A.vidproveedor 
				when '33' then 'Reacud. Claro $1'
				else isnull(A.vconcepto,'Recaud. Servicios')
			end vconcepto,
			
			isnull(B.nvalor ,0)  pago,
			A.vreferencia as vreferenciacomision,	
			sum(A.nvalor) as TotComision,
			A.idconciliacion,
			'N' vconciliadored,
			'S' vconciliadobanco,
			'N' vconciliadoeasy,
			'FALTANTE' vestadodescuadre,
			null
		from tb_detalle_transaccion_BANCO A left join TB_DETALLE_Transaccion_banco B
		on
			 substring(A.vreferencia,2,len(A.vreferencia)-1)= substring(B.vreferencia,2,len(B.vreferencia)-1)  and
			 B.vtipotransaccion='20'  and 
			 A.vfechacontable=B.vfechacontable and
			 A.vnumero!='1613' and 
			 B.ipendiente=0 and
			 A.idconciliacion=B.idconciliacion
		where
			A.vconciliadored='N' and
			A.vconciliadoeasy ='N' and
			A.idconciliacion =@idconciliacion and
			A.vvalida!='S'  and 
			A.ipendiente=0 and
			A.vtipotransaccion!='20'  and 
			A.vnumero!= '1613' and
			B.nvalor is null
		group by 
			A.vfechacontable,
			A.vreferencia,
			A.vidproveedor, 
			B.vreferencia,
			B.nvalor,
			A.idconciliacion,
			A.vconcepto
		
		--Actualizar el detalle de pago con la descripción del Producto	
		update T
			set 
				T.vconcepto=A.descripcion_easy
		from [DBREPORTS].dbo.HIP_RECAUDACION_SERVICIO T inner join producto_banco A
		on
			A.id_proveedor=T.vidproveedor and
			T.vconciliadored='S' 
		where
			T.idconciliacion=	@idconciliacion and
			A.descripcion_easy is not null
	
	end	--Fin de if (@opcion=2) 
	
	if(@opcion=3)
	begin
		--Quitar la marca de confirmación a los registros procesados
		update [DBREPORTS].dbo.HIP_RECAUDACION_SERVICIO
		set 
			idconfirmacion=null,
			idtrxmallaeasycomision=null
		where 
			idconfirmacion=@idconfirmacion
	
		--Escenario 1: Pagos que estan solo en el lado del banco
		update  T
		set 
			T.idconfirmacion=A.idconfirmacion,
			T.ntotalcomision=	case T.ntotalcomision
									when 0 then A.ncomisioncliente
									else  T.ntotalcomision
								end,
			T.idtrxmallaeasycomision=A.idtrxmalla
		from [DBREPORTS].dbo.HIP_RECAUDACION_SERVICIO T inner join TB_DETALLE_MALLACOMISION_SERVICIO A
		on
			T.vsecuencialunico=A.vsecuencialunico
		where
			T.vconciliadored='N' and 
			T.vconciliadobanco='S' and 
			T.vconciliadoeasy='N' and
			A.idconfirmacion=@idconfirmacion and
			T.idconfirmacion is  null and
			T.vfechatransaccion >= convert(varchar,  
													dateadd(d,-2, convert(datetime, @vfechainicial)),112
								) and
			T.vfechatransaccion <= convert(varchar,  
													dateadd(d,1, convert(datetime, @vfechafinal)),112
								) 
			
			
		--Escenario 2: Pagos que estan solo en el lado de Puntomatico
		update  T
		set 
			T.idconfirmacion=A.idconfirmacion,
			T.ntotalcomision=	case T.ntotalcomision
									when 0 then A.ncomisioncliente
									else  T.ntotalcomision
								end,
			T.idtrxmallaeasycomision=A.idtrxmalla
		from [DBREPORTS].dbo.HIP_RECAUDACION_SERVICIO T inner join TB_DETALLE_MALLACOMISION_SERVICIO A
		on
			--T.vreferenciapago=A.vsecuencialunico
			T.vsecuencialunico=A.vsecuencialunico
		where
			T.vconciliadored='N' and 
			T.vconciliadobanco='N' and 
			T.vconciliadoeasy='S' and
			A.idconfirmacion=@idconfirmacion and
			T.idconfirmacion is  null and
			--T.vfechatransaccion >=@vfechainicial and 
			T.vfechatransaccion >= convert(varchar,  
													dateadd(d,-2, convert(datetime, @vfechainicial)),112
								) and
			
			T.vfechatransaccion <= convert(varchar,  
													dateadd(d,1, convert(datetime, @vfechafinal)),112
								) 
			
		--Escenario 3: Pagos que hayan sido conciliados entre las  tres plataformas
		update  T
		set 
			T.idconfirmacion=A.idconfirmacion,
			T.ntotalcomision=	case T.ntotalcomision
									when 0 then A.ncomisioncliente
									else  T.ntotalcomision
								end,
			T.idtrxmallaeasycomision=A.idtrxmalla
		from [DBREPORTS].dbo.HIP_RECAUDACION_SERVICIO T inner join TB_DETALLE_MALLACOMISION_SERVICIO A
		on
			--T.vreferenciapago=substring(A.vsecuencialunico,2,len(A.vsecuencialunico)-1)
			T.vsecuencialunico=A.vsecuencialunico
		where
			T.vconciliadored='S' and 
			T.vconciliadobanco='S' and 
			T.vconciliadoeasy='S' and
			A.idconfirmacion=@idconfirmacion and
			T.idconfirmacion is  null and
			--T.vfechatransaccion >=@vfechainicial and
			T.vfechatransaccion >= convert(varchar,  
													dateadd(d,-2, convert(datetime, @vfechainicial)),112
								) and
			T.vfechatransaccion <= convert(varchar,  
													dateadd(d,1, convert(datetime, @vfechafinal)),112
								) 
			
		--Escenario 4: Pagos que esten en el Banco y en Puntomatico y no en la RED
		update  T
		set 
			T.idconfirmacion=A.idconfirmacion,
			T.ntotalcomision=	case T.ntotalcomision
									when 0 then A.ncomisioncliente
									else  T.ntotalcomision
								end,
		T.idtrxmallaeasycomision=A.idtrxmalla
		from [DBREPORTS].dbo.HIP_RECAUDACION_SERVICIO T inner join TB_DETALLE_MALLACOMISION_SERVICIO A
		on
			--T.vreferenciapago=substring(A.vsecuencialunico,2,len(A.vsecuencialunico)-1)
			T.vsecuencialunico=A.vsecuencialunico
		where
			T.vconciliadored='N' and 
			T.vconciliadobanco='S' and 
			T.vconciliadoeasy='S' and
			A.idconfirmacion=@idconfirmacion and
			T.idconfirmacion is  null and
			--T.vfechatransaccion >=@vfechainicial and 
			T.vfechatransaccion >= convert(varchar,  
													dateadd(d,-2, convert(datetime, @vfechainicial)),112
								) and
			T.vfechatransaccion <= convert(varchar,  
													dateadd(d,1, convert(datetime, @vfechafinal)),112
								) 
		
		--Escenario 5: Pagos que se encuentren en la Red y Puntomatico y no en el banco
		update  T
		set 
			T.idconfirmacion=A.idconfirmacion,
			T.ntotalcomision=	case T.ntotalcomision
									when 0 then A.ncomisioncliente
									else  T.ntotalcomision
								end,
			T.idtrxmallaeasycomision=A.idtrxmalla
		from [DBREPORTS].dbo.HIP_RECAUDACION_SERVICIO T inner join TB_DETALLE_MALLACOMISION_SERVICIO A
		on
			--'2' + T.vreferenciapago=A.vsecuencialunico
			T.vsecuencialunico=A.vsecuencialunico
		where
			T.vconciliadored='S' and 
			T.vconciliadobanco='N' and 
			T.vconciliadoeasy='S' and
			A.idconfirmacion=@idconfirmacion and
			T.idconfirmacion is  null and
			--T.vfechatransaccion >=@vfechainicial and
			T.vfechatransaccion >= convert(varchar,  
													dateadd(d,-2, convert(datetime, @vfechainicial)),112
								) and
			T.vfechatransaccion <= convert(varchar,  
													dateadd(d,1, convert(datetime, @vfechafinal)),112
								) 
			
		--Escenario 6: Pagos que se encuentren en la Red y el Banco y no en Puntomatico
		update  T
		set 
			T.idconfirmacion=A.idconfirmacion,
			T.ntotalcomision=	case T.ntotalcomision
									when 0 then A.ncomisioncliente
									else  T.ntotalcomision
								end,
			T.idtrxmallaeasycomision=A.idtrxmalla
		from [DBREPORTS].dbo.HIP_RECAUDACION_SERVICIO T inner join TB_DETALLE_MALLACOMISION_SERVICIO A
		on
			--T.vreferenciapago=substring(A.vsecuencialunico,2,len(A.vsecuencialunico)-1)
			T.vsecuencialunico=A.vsecuencialunico
		where
			T.vconciliadored='S' and 
			T.vconciliadobanco='S' and 
			T.vconciliadoeasy='N' and
			A.idconfirmacion=@idconfirmacion and
			T.idconfirmacion is  null and
			--T.vfechatransaccion >=@vfechainicial and
			
			T.vfechatransaccion >= convert(varchar,  
													dateadd(d,-2, convert(datetime, @vfechainicial)),112
								) and
			T.vfechatransaccion <= convert(varchar,  
													dateadd(d,1, convert(datetime, @vfechafinal)),112
								) 
		
		--Escenario 7: Pagos que se encuentren solamente en la red
		update  T
		set 
			T.idconfirmacion=A.idconfirmacion,
			T.ntotalcomision=	case T.ntotalcomision
									when 0 then A.ncomisioncliente
									else  T.ntotalcomision
								end,
			T.idtrxmallaeasycomision=A.idtrxmalla
		from [DBREPORTS].dbo.HIP_RECAUDACION_SERVICIO T inner join TB_DETALLE_MALLACOMISION_SERVICIO A
		on
			--T.vreferenciapago=A.vsecuencialunico
			T.vsecuencialunico=A.vsecuencialunico
		where
			T.vconciliadored='S' and 
			T.vconciliadobanco='N' and 
			T.vconciliadoeasy='N' and
			A.idconfirmacion=@idconfirmacion and
			T.idconfirmacion is  null and
			--T.vfechatransaccion >=@vfechainicial and
			T.vfechatransaccion >= convert(varchar,  
													dateadd(d,-2, convert(datetime, @vfechainicial)),112
								) and
			T.vfechatransaccion <= convert(varchar,  
													dateadd(d,1, convert(datetime, @vfechafinal)),112
								) 
		
		
		--Actualizar los id transaccional
		update A
		set 
			A.ntxGencounter= TP.ntxGencounter
		from  [DBREPORTS].dbo.HIP_RECAUDACION_SERVICIO A inner join tptransactionlog TP
		on
			A.vreferenciapago=TP.ntxautorizationhostBPAC 
		where
			A.idconfirmacion=@idconfirmacion and A.vconciliadored='S' 
		
		--Igualar las Comisioones del Banco con la que Proporciona EasySoft
		update  A
		set A.ntotalcomision= B.ncomisioncliente
		from  [DBREPORTS].dbo.HIP_RECAUDACION_SERVICIO A inner join TB_DETALLE_MALLACOMISION_SERVICIO B
		on
			B.idconfirmacion=@idconfirmacion and
			A.vsecuencialunico=B.vsecuencialunico and
			A.idconfirmacion=B.idconfirmacion
		
		--Obtener las cantidad de transacciones y comisión de reportado por Puntomatico	
		select 
			@icantidadtrxred=count(*) ,
			@ncomisionred= sum(ntotalcomision*0.6)
		from  [DBREPORTS].dbo.HIP_RECAUDACION_SERVICIO
		where
			idconfirmacion=@idconfirmacion
		
		--Obtener las cantidades de transaciones y valor de comisión reportado por la Red
		select
			@icantidadredeasy=count(*),
			@ncomisioneasy=sum(ncomisionagente)
		from dbo.TB_DETALLE_MALLACOMISION_SERVICIO
		where
			idconfirmacion=@idconfirmacion
		
		--Actualizar la información de cantidad de transacciones y comisiones
		update dbo.TB_CONFIRMACION_MALLACOMISION_SERVICIO
		set 
			icantidadtrxred=@icantidadtrxred,
			ncomisionred=@ncomisionred,
			icantidadredeasy=@icantidadredeasy,
			ncomisioneasy=@ncomisioneasy
		where
			idconfirmacion=@idconfirmacion
	end
	
end