GenerateBoosterPack: ; 1e1c4 (7:61c4)
	push hl
	push bc
	push de
	ld [wBoosterDataIndex], a
.noCardsFoundLoop
	call InitBoosterData
	call GenerateBoosterEnergy
	call GenerateBoosterCard
	jr c, .noCardsFoundLoop
	call CopyBoosterEnergiesToBooster
	call AddBoosterCardsToCollection
	pop de
	pop bc
	pop hl
	ret

GenerateBoosterCard: ; 1e1df (7:61df)
	ld a, STAR
	ld [wBoosterCurRarity], a
.generateCardLoop
	call FindCurRarityChance
	ld a, [hl]
	or a
	jr z, .noMoreOfCurrentRarity
	call FindCardsInSetAndRarity
	call FindTotalTypeChances
	or a
	jr z, .noValidCards
	call Random
	call DetermineBoosterCardType
	call FindBoosterCard
	call UpdateBoosterCardTypesChanceByte
	call AddCardToBoosterList
	call FindCurRarityChance
	dec [hl]
	jr .generateCardLoop
.noMoreOfCurrentRarity
	ld a, [wBoosterCurRarity]
	dec a
	ld [wBoosterCurRarity], a
	bit 7, a ; any rarity left to check?
	jr z, .generateCardLoop
	or a
	ret
.noValidCards
	rst $38
	scf
	ret

FindCurRarityChance: ; 1e219 (7:6219)
	push bc
	ld hl, wBoosterDataCommonAmount
	ld a, [wBoosterCurRarity]
	ld c, a
	ld b, $0
	add hl, bc
	pop bc
	ret

FindCardsInSetAndRarity: ; 1e226 (7:6226)
	ld c, NUM_BOOSTER_CARD_TYPES
	ld hl, wBoosterAmountOfCardTypeTable
	xor a
.deleteTypeTableLoop
	ld [hli], a
	dec c
	jr nz, .deleteTypeTableLoop
	xor a
	ld hl, wBoosterViableCardList
	ld [hl], a
	ld de, $1
.checkCardViableLoop
	push de
	ld a, e
	ld [wBoosterTempData], a
	call CheckByteInWramZeroed
	jr c, .finishedWithCurrentCard
	call CheckCardViable
	jr c, .finishedWithCurrentCard
	ld a, [wBoosterCurrentCardType]
	call GetCardType
	push af
	push hl
	ld c, a
	ld b, $00
	ld hl, wBoosterAmountOfCardTypeTable
	add hl, bc
	inc [hl]
	pop hl
	ld a, [wBoosterTempData]
	ld [hli], a
	pop af
	ld [hli], a
	xor a
	ld [hl], a
.finishedWithCurrentCard
	pop de
	inc e
	ld a, e
	cp NUM_CARDS + 1
	jr c, .checkCardViableLoop
	ret

CheckCardViable: ; 1e268 (7:6268)
	push bc
	ld a, e
	call GetCardHeader
	ld [wBoosterCurrentCardType], a
	ld a, b
	ld [wBoosterCurrentCardRarity], a
	ld a, c
	ld [wBoosterCurrentCardSet], a
	ld a, [wBoosterCurrentCardRarity]
	ld c, a
	ld a, [wBoosterCurRarity]
	cp c
	jr nz, .invalidCard
	ld a, [wBoosterCurrentCardType]
	call GetCardType
	cp BOOSTER_CARD_TYPE_ENERGY
	jr z, .returnValidCard
	ld a, [wBoosterCurrentCardSet]
	swap a
	and $0f
	ld c, a
	ld a, [wBoosterDataCurSet]
	cp c
	jr nz, .invalidCard
.returnValidCard
	or a
	jr .return
.invalidCard
	scf
.return
	pop bc
	ret

; Map a card's TYPE_* constant given in a to its BOOSTER_CARD_TYPE_* constant
GetCardType: ; 1e2a0 (7:62a0)
	push hl
	push bc
	ld hl, CardTypeTable
	cp NUM_CARD_TYPES
	jr nc, .loadType
	ld c, a
	ld b, $00
	add hl, bc
.loadType
	ld a, [hl]
	pop bc
	pop hl
	ret

CardTypeTable:  ; 1e2b1 (7:62b1)
	db BOOSTER_CARD_TYPE_FIRE      ; TYPE_PKMN_FIRE
	db BOOSTER_CARD_TYPE_GRASS     ; TYPE_PKMN_GRASS
	db BOOSTER_CARD_TYPE_LIGHTNING ; TYPE_PKMN_LIGHTNING
	db BOOSTER_CARD_TYPE_WATER     ; TYPE_PKMN_WATER
	db BOOSTER_CARD_TYPE_FIGHTING  ; TYPE_PKMN_FIGHTING
	db BOOSTER_CARD_TYPE_PSYCHIC   ; TYPE_PKMN_PSYCHIC
	db BOOSTER_CARD_TYPE_COLORLESS ; TYPE_PKMN_COLORLESS
	db BOOSTER_CARD_TYPE_TRAINER   ; TYPE_PKMN_UNUSED
	db BOOSTER_CARD_TYPE_ENERGY    ; TYPE_ENERGY_FIRE
	db BOOSTER_CARD_TYPE_ENERGY    ; TYPE_ENERGY_GRASS
	db BOOSTER_CARD_TYPE_ENERGY    ; TYPE_ENERGY_LIGHTNING
	db BOOSTER_CARD_TYPE_ENERGY    ; TYPE_ENERGY_WATER
	db BOOSTER_CARD_TYPE_ENERGY    ; TYPE_ENERGY_FIGHTING
	db BOOSTER_CARD_TYPE_ENERGY    ; TYPE_ENERGY_PSYCHIC
	db BOOSTER_CARD_TYPE_ENERGY    ; TYPE_ENERGY_COLORLESS
	db BOOSTER_CARD_TYPE_TRAINER   ; TYPE_ENERGY_UNUSED
	db BOOSTER_CARD_TYPE_TRAINER   ; TYPE_TRAINER

FindTotalTypeChances: ; 1e2c2 (7:62c2)
	ld c, NUM_BOOSTER_CARD_TYPES
	xor a
	ld hl, wBoosterTempTypeChanceTable
.deleteTempTypeChanceTableLoop
	ld [hli], a
	dec c
	jr nz, .deleteTempTypeChanceTableLoop
	ld [wd4ca], a
	ld bc, $00
.checkIfTypeIsValid
	push bc
	ld hl, wBoosterAmountOfCardTypeTable
	add hl, bc
	ld a, [hl]
	or a
	jr z, .amountOfTypeOrChanceZero
	ld hl, wBoosterDataTypeChanceData
	add hl, bc
	ld a, [hl]
	or a
	jr z, .amountOfTypeOrChanceZero
	ld hl, wBoosterTempTypeChanceTable
	add hl, bc
	ld [hl], a
	ld a, [wd4ca]
	add [hl]
	ld [wd4ca], a
.amountOfTypeOrChanceZero
	pop bc
	inc c
	ld a, c
	cp $09
	jr c, .checkIfTypeIsValid
	ld a, [wd4ca]
	ret

DetermineBoosterCardType: ; 1e2fa (7:62fa)
	ld [wd4ca], a
	ld c, $00
	ld hl, wBoosterTempTypeChanceTable
.loopThroughCardTypes
	ld a, [hl]
	or a
	jr z, .skipNoChanceType
	ld a, [wd4ca]
	sub [hl]
	ld [wd4ca], a
	jr c, .foundCardType
.skipNoChanceType
	inc hl
	inc c
	ld a, c
	cp a, NUM_BOOSTER_CARD_TYPES
	jr c, .loopThroughCardTypes
	ld a, $08
.foundCardType
	ld a, c
	ld [wBoosterSelectedCardType], a
	ret

FindBoosterCard: ; 1e31d (7:631d)
	ld a, [wBoosterSelectedCardType]
	ld c, a
	ld b, $00
	ld hl, wBoosterAmountOfCardTypeTable
	add hl, bc
	ld a, [hl]
	call Random
	ld [wd4ca], a
	ld hl, wBoosterViableCardList
.findMatchingCardLoop
	ld a, [hli]
	or a
	jr z, .noValidCardFound
	ld [wBoosterTempData], a
	ld a, [wBoosterSelectedCardType]
	cp [hl]
	jr nz, .cardIncorrectType
	ld a, [wd4ca]
	or a
	jr z, .returnWithCurrentCard
	dec a
	ld [wd4ca], a
.cardIncorrectType
	inc hl
	jr .findMatchingCardLoop
.returnWithCurrentCard
	or a
	ret
.noValidCardFound
	rst $38
	scf
	ret

; lowers the chance of getting the same type multiple times
UpdateBoosterCardTypesChanceByte: ; 1e350 (7:6350)
	push hl
	push bc
	ld a, [wBoosterSelectedCardType]
	ld c, a
	ld b, $00
	ld hl, wBoosterDataTypeChanceData
	add hl, bc
	ld a,[wBoosterDataAveragedChance]
	ld c, a
	ld a, [hl]
	sub c
	ld [hl], a
	jr z, .chanceLessThanOne
	jr nc, .stillSomeChanceLeft
.chanceLessThanOne
	ld a, $01
	ld [hl], a
.stillSomeChanceLeft
	pop bc
	pop hl
	ret

GenerateBoosterEnergy: ; 1e3db (7:63db)
	ld hl, wBoosterDataEnergyFunctionPointer + 1
	ld a, [hld]
	or a
	jr z, .noFunctionPointer
	ld l, [hl]
	ld h, a
	jp hl
.noFunctionPointer
	ld a, [hl]
	or a
	ret z
	push af
	call AddBoosterEnergyToWram
	pop af
	ret

AddBoosterEnergyToWram: ; 1e380 (7:6380)
	ld [wBoosterTempData], a
	call AddCardToBoosterEnergies
	ret

GenerateEndingEnergy: ; 1e387 (7:6387)
	ld a, $06
	call Random
	add a, $01
	jr AddBoosterEnergyToWram

GenerateRandomEnergyBoosterPack:  ; 1e390 (7:6390)
	ld a, $0a
.generateEnergyLoop
	push af
	call GenerateEndingEnergy
	pop af
	dec a
	jr nz, .generateEnergyLoop
	jr ZeroBoosterRarityData

GenerateEnergyBoosterLightningFire:  ; 1e39c (7:639c)
	ld hl, EnergyBoosterLightningFireData
	jr CreateEnergyBooster

GenerateEnergyBoosterWaterFighting:  ; 1e3a1 (7:63a1)
	ld hl, EnergyBoosterWaterFightingData
	jr CreateEnergyBooster

GenerateEnergyBoosterGrassPsychic:  ; 1e3a6 (7:63a6)
	ld hl, EnergyBoosterGrassPsychicData
	jr CreateEnergyBooster

CreateEnergyBooster:  ; 1e3ab (7:63ab)
	ld b, $02
.addTwoEnergiesToBoosterLoop
	ld c, $05
.addEnergyToBoosterLoop
	push hl
	push bc
	ld a, [hl]
	call AddBoosterEnergyToWram
	pop bc
	pop hl
	dec c
	jr nz, .addEnergyToBoosterLoop
	inc hl
	dec b
	jr nz, .addTwoEnergiesToBoosterLoop
ZeroBoosterRarityData:
	xor a
	ld [wBoosterDataCommonAmount], a
	ld [wBoosterDataUncommonAmount], a
	ld [wBoosterDataRareAmount], a
	ret

EnergyBoosterLightningFireData:
	db LIGHTNING_ENERGY, FIRE_ENERGY
EnergyBoosterWaterFightingData:
	db WATER_ENERGY, FIGHTING_ENERGY
EnergyBoosterGrassPsychicData:
	db GRASS_ENERGY, PSYCHIC_ENERGY

AddCardToBoosterEnergies: ; 1e3cf (7:63cf)
	push hl
	ld hl, wPlayerDeck + $b
	call CopyToFirstEmptyByte
	call AddBoosterCardToTempCardCollection
	pop hl
	ret

AddCardToBoosterList: ; 1e3db (7:63db)
	push hl
	ld hl, wPlayerDeck
	call CopyToFirstEmptyByte
	call AddBoosterCardToTempCardCollection
	pop hl
	ret

CopyToFirstEmptyByte: ; 1e3e7 (7:63e7)
	ld a, [hli]
	or a
	jr nz, CopyToFirstEmptyByte
	dec hl
	ld a, [wBoosterTempData]
	ld [hli], a
	xor a
	ld [hl], a
	ret

CopyBoosterEnergiesToBooster: ; 1e3f3 (7:63f3)
	push hl
	ld hl, wPlayerDeck + $b
.loopThroughExtraCards
	ld a, [hli]
	or a
	jr z, .endOfCards
	ld [wBoosterTempData], a
	push hl
	ld hl, wPlayerDeck
	call CopyToFirstEmptyByte
	pop hl
	jr .loopThroughExtraCards
.endOfCards
	pop hl
	ret

AddBoosterCardsToCollection:; 1e40a (7:640a)
	push hl
	ld hl, wPlayerDeck
.addCardsLoop
	ld a, [hli]
	or a
	jr z, .noCardsLeft
	call AddCardToCollection
	jr .addCardsLoop
.noCardsLeft
	pop hl
	ret

AddBoosterCardToTempCardCollection: ; 1e419 (7:6419)
	push hl
	ld h, wTempCardCollection >> 8
	ld a, [wBoosterTempData]
	ld l, a
	inc [hl]
	pop hl
	ret

CheckByteInWramZeroed: ; 1e423 (7:6423)
	push hl
	ld h, wTempCardCollection >> 8
	ld a, [wBoosterTempData]
	ld l, a
	ld a, [hl]
	pop hl
	cp $01
	ccf
	ret

; clears wPlayerDeck and wTempCardCollection
; copies rarity amounts to ram and averages them into wBoosterDataAveragedChance
InitBoosterData: ; 1e430 (7:6430)
	ld c, $16
	ld hl, wPlayerDeck
	xor a
.clearPlayerDeckLoop
	ld [hli], a
	dec c
	jr nz, .clearPlayerDeckLoop
	ld c, $00
	ld hl, wTempCardCollection
	xor a
.clearTempCardCollectionLoop
	ld [hli], a
	dec c
	jr nz, .clearTempCardCollectionLoop
	call FindBoosterDataPointer
	ld de, wBoosterDataCurSet
	ld bc, $c
	call CopyDataHLtoDE
	call LoadRarityAmountsToWram
	ld bc, $0
	ld d, NUM_BOOSTER_CARD_TYPES
	ld e, $0
	ld hl, wBoosterDataTypeChanceData
.addChanceBytesLoop
	ld a, [hli]
	or a
	jr z, .skipChanceByte
	add c
	ld c, a
	inc e
.skipChanceByte
	dec d
	jr nz, .addChanceBytesLoop
	call DivideBCbyDE
	ld a, c
	ld [wBoosterDataAveragedChance], a
	ret

FindBoosterDataPointer: ; 1e46f (7:646f)
	push bc
	ld a, [wBoosterDataIndex]
	add a
	ld c, a
	ld b, $0
	ld hl, BoosterDataJumptable
	add hl, bc
	ld a, [hli]
	ld h, [hl]
	ld l, a
	pop bc
	ret

BoosterDataJumptable: ; 1e480 (7:6480)
	dw PackColosseumNeutral
	dw PackColosseumGrass
	dw PackColosseumFire
	dw PackColosseumWater
	dw PackColosseumLightning
	dw PackColosseumFighting
	dw PackColosseumTrainer
	dw PackEvolutionNeutral
	dw PackEvolutionGrass
	dw PackEvolutionNeutralFireEnergy
	dw PackEvolutionWater
	dw PackEvolutionFighting
	dw PackEvolutionPsychic
	dw PackEvolutionTrainer
	dw PackMysteryNeutral
	dw PackMysteryGrassColorless
	dw PackMysteryWaterColorless
	dw PackMysteryLightningColorless
	dw PackMysteryFightingColorless
	dw PackMysteryTrainerColorless
	dw PackLaboratoryMostlyNeutral
	dw PackLaboratoryGrass
	dw PackLaboratoryWater
	dw PackLaboratoryPsychic
	dw PackLaboratoryTrainer
	dw PackEnergyLightningFire
	dw PackEnergyWaterFighting
	dw PackEnergyGrassPsychic
	dw PackRandomEnergies

LoadRarityAmountsToWram: ; 1e4ba (7:64ba)
	ld a, [wBoosterDataCurSet]
	add a
	add a
	ld c, a
	ld b, $00
	ld hl, BoosterSetRarityAmountTable
	add hl, bc
	inc hl
	ld a, [hli]
	ld [wBoosterDataCommonAmount], a
	ld a, [hli]
	ld [wBoosterDataUncommonAmount], a
	ld a, [hli]
	ld [wBoosterDataRareAmount], a
	ret

BoosterSetRarityAmountTable: ; 1e4d4 (7::64d4)
	db $01, $05, $03, $01 ; other, commons, uncommons, rares
	db $01, $05, $03, $01 ; other, commons, uncommons, rares
	db $00, $06, $03, $01 ; other, commons, uncommons, rares
	db $00, $06, $03, $01 ; other, commons, uncommons, rares

PackColosseumNeutral:: ; 1e4e4 (7:64e4)
	db COLOSSEUM >> 4 ; booster pack set
	dw GenerateEndingEnergy ; energy or energy generation function

; Card Type Chances
	db $14 ; Grass Type Chance
	db $14 ; Fire Type Chance
	db $14 ; Water Type Chance
	db $14 ; Lightning Type Chance
	db $14 ; Fighting Type Chance
	db $14 ; Psychic Type Chance
	db $14 ; Colorless Type Chance
	db $14 ; Trainer Card Chance
	db $00 ; Energy Card Chance

PackColosseumGrass:: ; 1e4f0 (7:64f0)
	db COLOSSEUM >> 4 ; booster pack set
	dw GRASS_ENERGY  ; energy or energy generation function

; Card Type Chances
	db $30 ; Grass Type Chance
	db $10 ; Fire Type Chance
	db $10 ; Water Type Chance
	db $10 ; Lightning Type Chance
	db $10 ; Fighting Type Chance
	db $10 ; Psychic Type Chance
	db $10 ; Colorless Type Chance
	db $10 ; Trainer Card Chance
	db $00 ; Energy Card Chance

PackColosseumFire:: ; 1e4fc (7:64fc)
	db COLOSSEUM >> 4 ; booster pack set
	dw FIRE_ENERGY  ; energy or energy generation function

; Card Type Chances
	db $10 ; Grass Type Chance
	db $30 ; Fire Type Chance
	db $10 ; Water Type Chance
	db $10 ; Lightning Type Chance
	db $10 ; Fighting Type Chance
	db $10 ; Psychic Type Chance
	db $10 ; Colorless Type Chance
	db $10 ; Trainer Card Chance
	db $00 ; Energy Card Chance

PackColosseumWater:: ; 1e508 (7:6508)
	db COLOSSEUM >> 4 ; booster pack set
	dw WATER_ENERGY ; energy or energy generation function

; Card Type Chances
	db $10 ; Grass Type Chance
	db $10 ; Fire Type Chance
	db $30 ; Water Type Chance
	db $10 ; Lightning Type Chance
	db $10 ; Fighting Type Chance
	db $10 ; Psychic Type Chance
	db $10 ; Colorless Type Chance
	db $10 ; Trainer Card Chance
	db $00 ; Energy Card Chance

PackColosseumLightning:: ; 1e514 (7:6514)
	db COLOSSEUM >> 4 ; booster pack set
	dw LIGHTNING_ENERGY ; energy or energy generation function

; Card Type Chances
	db $10 ; Grass Type Chance
	db $10 ; Fire Type Chance
	db $10 ; Water Type Chance
	db $30 ; Lightning Type Chance
	db $10 ; Fighting Type Chance
	db $10 ; Psychic Type Chance
	db $10 ; Colorless Type Chance
	db $10 ; Trainer Card Chance
	db $00 ; Energy Card Chance

PackColosseumFighting:: ; 1e520 (7:6520)
	db COLOSSEUM >> 4 ; booster pack set
	dw FIGHTING_ENERGY ; energy or energy generation function

; Card Type Chances
	db $10 ; Grass Type Chance
	db $10 ; Fire Type Chance
	db $10 ; Water Type Chance
	db $10 ; Lightning Type Chance
	db $30 ; Fighting Type Chance
	db $10 ; Psychic Type Chance
	db $10 ; Colorless Type Chance
	db $10 ; Trainer Card Chance
	db $00 ; Energy Card Chance

PackColosseumTrainer:: ; 1e52c (7:652c)
	db COLOSSEUM >> 4 ; booster pack set
	dw GenerateEndingEnergy ; energy or energy generation function

; Card Type Chances
	db $10 ; Grass Type Chance
	db $10 ; Fire Type Chance
	db $10 ; Water Type Chance
	db $10 ; Lightning Type Chance
	db $10 ; Fighting Type Chance
	db $10 ; Psychic Type Chance
	db $10 ; Colorless Type Chance
	db $30 ; Trainer Card Chance
	db $00 ; Energy Card Chance

PackEvolutionNeutral:: ; 1e538 (7:6538)
	db EVOLUTION >> 4 ; booster pack set
	dw GenerateEndingEnergy ; energy or energy generation function

; Card Type Chances
	db $14 ; Grass Type Chance
	db $14 ; Fire Type Chance
	db $14 ; Water Type Chance
	db $14 ; Lightning Type Chance
	db $14 ; Fighting Type Chance
	db $14 ; Psychic Type Chance
	db $14 ; Colorless Type Chance
	db $14 ; Trainer Card Chance
	db $00 ; Energy Card Chance

PackEvolutionGrass:: ; 1e544 (7:6544)
	db EVOLUTION >> 4 ; booster pack set
	dw GRASS_ENERGY ; energy or energy generation function

; Card Type Chances
	db $30 ; Grass Type Chance
	db $10 ; Fire Type Chance
	db $10 ; Water Type Chance
	db $10 ; Lightning Type Chance
	db $10 ; Fighting Type Chance
	db $10 ; Psychic Type Chance
	db $10 ; Colorless Type Chance
	db $10 ; Trainer Card Chance
	db $00 ; Energy Card Chance

PackEvolutionNeutralFireEnergy:: ; 1e550 (7:6550)
	db EVOLUTION >> 4 ; booster pack set
	dw FIRE_ENERGY ; energy or energy generation function

; Card Type Chances
	db $14 ; Grass Type Chance
	db $14 ; Fire Type Chance
	db $14 ; Water Type Chance
	db $14 ; Lightning Type Chance
	db $14 ; Fighting Type Chance
	db $14 ; Psychic Type Chance
	db $14 ; Colorless Type Chance
	db $14 ; Trainer Card Chance
	db $00 ; Energy Card Chance

PackEvolutionWater:: ; 1e55c (7:655c)
	db EVOLUTION >> 4 ; booster pack set
	dw WATER_ENERGY ; energy or energy generation function

; Card Type Chances
	db $10 ; Grass Type Chance
	db $10 ; Fire Type Chance
	db $30 ; Water Type Chance
	db $10 ; Lightning Type Chance
	db $10 ; Fighting Type Chance
	db $10 ; Psychic Type Chance
	db $10 ; Colorless Type Chance
	db $10 ; Trainer Card Chance
	db $00 ; Energy Card Chance

PackEvolutionFighting:: ; 1e568 (7:6568)
	db EVOLUTION >> 4 ; booster pack set
	dw FIGHTING_ENERGY ; energy or energy generation function

; Card Type Chances
	db $10 ; Grass Type Chance
	db $10 ; Fire Type Chance
	db $10 ; Water Type Chance
	db $10 ; Lightning Type Chance
	db $30 ; Fighting Type Chance
	db $10 ; Psychic Type Chance
	db $10 ; Colorless Type Chance
	db $10 ; Trainer Card Chance
	db $00 ; Energy Card Chance

PackEvolutionPsychic:: ; 1e574 (7:6574)
	db EVOLUTION >> 4 ; booster pack set
	dw PSYCHIC_ENERGY ; energy or energy generation function

; Card Type Chances
	db $10 ; Grass Type Chance
	db $10 ; Fire Type Chance
	db $10 ; Water Type Chance
	db $10 ; Lightning Type Chance
	db $10 ; Fighting Type Chance
	db $30 ; Psychic Type Chance
	db $10 ; Colorless Type Chance
	db $10 ; Trainer Card Chance
	db $00 ; Energy Card Chance

PackEvolutionTrainer:: ; 1e580 (7:6580)
	db EVOLUTION >> 4 ; booster pack set
	dw GenerateEndingEnergy ; energy or energy generation function

; Card Type Chances
	db $10 ; Grass Type Chance
	db $10 ; Fire Type Chance
	db $10 ; Water Type Chance
	db $10 ; Lightning Type Chance
	db $10 ; Fighting Type Chance
	db $10 ; Psychic Type Chance
	db $10 ; Colorless Type Chance
	db $30 ; Trainer Card Chance
	db $00 ; Energy Card Chance

PackMysteryNeutral:: ; 1e58c (7:658c)
	db MYSTERY >> 4 ; booster pack set
	dw $0000 ; energy or energy generation function

; Card Type Chances
	db $11 ; Grass Type Chance
	db $11 ; Fire Type Chance
	db $11 ; Water Type Chance
	db $11 ; Lightning Type Chance
	db $11 ; Fighting Type Chance
	db $11 ; Psychic Type Chance
	db $11 ; Colorless Type Chance
	db $11 ; Trainer Card Chance
	db $11 ; Energy Card Chance

PackMysteryGrassColorless:: ; 1e598 (7:6598)
	db MYSTERY >> 4 ; booster pack set
	dw $0000 ; energy or energy generation function

; Card Type Chances
	db $30 ; Grass Type Chance
	db $0C ; Fire Type Chance
	db $0C ; Water Type Chance
	db $0C ; Lightning Type Chance
	db $0C ; Fighting Type Chance
	db $0C ; Psychic Type Chance
	db $16 ; Colorless Type Chance
	db $0C ; Trainer Card Chance
	db $0C ; Energy Card Chance

PackMysteryWaterColorless:: ; 1e5a4 (7:65a4)
	db MYSTERY >> 4 ; booster pack set
	dw $0000 ; energy or energy generation function

; Card Type Chances
	db $0C ; Grass Type Chance
	db $0C ; Fire Type Chance
	db $30 ; Water Type Chance
	db $0C ; Lightning Type Chance
	db $0C ; Fighting Type Chance
	db $0C ; Psychic Type Chance
	db $16 ; Colorless Type Chance
	db $0C ; Trainer Card Chance
	db $0C ; Energy Card Chance

PackMysteryLightningColorless:: ; 1e5b0 (7:65b0)
	db MYSTERY >> 4 ; booster pack set
	dw $0000 ; energy or energy generation function

; Card Type Chances
	db $0C ; Grass Type Chance
	db $0C ; Fire Type Chance
	db $0C ; Water Type Chance
	db $30 ; Lightning Type Chance
	db $0C ; Fighting Type Chance
	db $0C ; Psychic Type Chance
	db $16 ; Colorless Type Chance
	db $0C ; Trainer Card Chance
	db $0C ; Energy Card Chance

PackMysteryFightingColorless:: ; 1e5bc (7:65bc)
	db MYSTERY >> 4 ; booster pack set
	dw $0000 ; energy or energy generation function

; Card Type Chances
	db $0C ; Grass Type Chance
	db $0C ; Fire Type Chance
	db $0C ; Water Type Chance
	db $0C ; Lightning Type Chance
	db $30 ; Fighting Type Chance
	db $0C ; Psychic Type Chance
	db $16 ; Colorless Type Chance
	db $0C ; Trainer Card Chance
	db $0C ; Energy Card Chance

PackMysteryTrainerColorless:: ; 1e5c8 (7:65c8)
	db MYSTERY >> 4 ; booster pack set
	dw $0000 ; energy or energy generation function

; Card Type Chances
	db $0C ; Grass Type Chance
	db $0C ; Fire Type Chance
	db $0C ; Water Type Chance
	db $0C ; Lightning Type Chance
	db $0C ; Fighting Type Chance
	db $0C ; Psychic Type Chance
	db $16 ; Colorless Type Chance
	db $30 ; Trainer Card Chance
	db $0C ; Energy Card Chance

PackLaboratoryMostlyNeutral:: ; 1e5d4 (7:65d4)
	db LABORATORY >> 4 ; booster pack set
	dw $0000 ; energy or energy generation function

; Card Type Chances
	db $14 ; Grass Type Chance
	db $14 ; Fire Type Chance
	db $14 ; Water Type Chance
	db $14 ; Lightning Type Chance
	db $10 ; Fighting Type Chance
	db $14 ; Psychic Type Chance
	db $14 ; Colorless Type Chance
	db $18 ; Trainer Card Chance
	db $00 ; Energy Card Chance

PackLaboratoryGrass:: ; 1e5e0 (7:65e0)
	db LABORATORY >> 4 ; booster pack set
	dw $0000 ; energy or energy generation function

; Card Type Chances
	db $30 ; Grass Type Chance
	db $10 ; Fire Type Chance
	db $10 ; Water Type Chance
	db $10 ; Lightning Type Chance
	db $10 ; Fighting Type Chance
	db $10 ; Psychic Type Chance
	db $10 ; Colorless Type Chance
	db $10 ; Trainer Card Chance
	db $00 ; Energy Card Chance

PackLaboratoryWater:: ; 1e5ec (7:65ec)
	db LABORATORY >> 4 ; booster pack set
	dw $0000 ; energy or energy generation function

; Card Type Chances
	db $10 ; Grass Type Chance
	db $10 ; Fire Type Chance
	db $30 ; Water Type Chance
	db $10 ; Lightning Type Chance
	db $10 ; Fighting Type Chance
	db $10 ; Psychic Type Chance
	db $10 ; Colorless Type Chance
	db $10 ; Trainer Card Chance
	db $00 ; Energy Card Chance

PackLaboratoryPsychic:: ; 1e5f8 (7:65f8)
	db LABORATORY >> 4 ; booster pack set
	dw $0000 ; energy or energy generation function

; Card Type Chances
	db $10 ; Grass Type Chance
	db $10 ; Fire Type Chance
	db $10 ; Water Type Chance
	db $10 ; Lightning Type Chance
	db $10 ; Fighting Type Chance
	db $30 ; Psychic Type Chance
	db $10 ; Colorless Type Chance
	db $10 ; Trainer Card Chance
	db $00 ; Energy Card Chance

PackLaboratoryTrainer:: ; 1e604 (7:6604)
	db LABORATORY >> 4 ; booster pack set
	dw $0000 ; energy or energy generation function

; Card Type Chances
	db $10 ; Grass Type Chance
	db $10 ; Fire Type Chance
	db $10 ; Water Type Chance
	db $10 ; Lightning Type Chance
	db $10 ; Fighting Type Chance
	db $10 ; Psychic Type Chance
	db $10 ; Colorless Type Chance
	db $30 ; Trainer Card Chance
	db $00 ; Energy Card Chance

PackEnergyLightningFire:: ; 1e610 (7:6610)
	db COLOSSEUM >> 4 ; booster pack set
	dw GenerateEnergyBoosterLightningFire ; energy or energy generation function

; Card Type Chances
	db $00 ; Grass Type Chance
	db $00 ; Fire Type Chance
	db $00 ; Water Type Chance
	db $00 ; Lightning Type Chance
	db $00 ; Fighting Type Chance
	db $00 ; Psychic Type Chance
	db $00 ; Colorless Type Chance
	db $00 ; Trainer Card Chance
	db $00 ; Energy Card Chance

PackEnergyWaterFighting:: ; 1e61c (7:661c)
	db COLOSSEUM >> 4 ; booster pack set
	dw GenerateEnergyBoosterWaterFighting ; energy or energy generation function

; Card Type Chances
	db $00 ; Grass Type Chance
	db $00 ; Fire Type Chance
	db $00 ; Water Type Chance
	db $00 ; Lightning Type Chance
	db $00 ; Fighting Type Chance
	db $00 ; Psychic Type Chance
	db $00 ; Colorless Type Chance
	db $00 ; Trainer Card Chance
	db $00 ; Energy Card Chance

PackEnergyGrassPsychic:: ; 1e628 (7:6628)
	db COLOSSEUM >> 4 ; booster pack set
	dw GenerateEnergyBoosterGrassPsychic ; energy or energy generation function

; Card Type Chances
	db $00 ; Grass Type Chance
	db $00 ; Fire Type Chance
	db $00 ; Water Type Chance
	db $00 ; Lightning Type Chance
	db $00 ; Fighting Type Chance
	db $00 ; Psychic Type Chance
	db $00 ; Colorless Type Chance
	db $00 ; Trainer Card Chance
	db $00 ; Energy Card Chance

PackRandomEnergies:: ; 1e634 (7:6634)
	db COLOSSEUM >> 4 ; booster pack set
	dw GenerateRandomEnergyBoosterPack ; energy or energy generation function

; Card Type Chances
	db $00 ; Grass Type Chance
	db $00 ; Fire Type Chance
	db $00 ; Water Type Chance
	db $00 ; Lightning Type Chance
	db $00 ; Fighting Type Chance
	db $00 ; Psychic Type Chance
	db $00 ; Colorless Type Chance
	db $00 ; Trainer Card Chance
	db $00 ; Energy Card Chance

	INCROM $1e640, $20000
