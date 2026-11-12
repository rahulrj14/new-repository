// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'db.dart';

// ignore_for_file: type=lint
class $SessionsTable extends Sessions
    with TableInfo<$SessionsTable, SessionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endedAtMeta = const VerificationMeta(
    'endedAt',
  );
  @override
  late final GeneratedColumn<DateTime> endedAt = GeneratedColumn<DateTime>(
    'ended_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _plannedMinutesMeta = const VerificationMeta(
    'plannedMinutes',
  );
  @override
  late final GeneratedColumn<int> plannedMinutes = GeneratedColumn<int>(
    'planned_minutes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lockedSecondsMeta = const VerificationMeta(
    'lockedSeconds',
  );
  @override
  late final GeneratedColumn<int> lockedSeconds = GeneratedColumn<int>(
    'locked_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cracksMeta = const VerificationMeta('cracks');
  @override
  late final GeneratedColumn<int> cracks = GeneratedColumn<int>(
    'cracks',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completedMeta = const VerificationMeta(
    'completed',
  );
  @override
  late final GeneratedColumn<bool> completed = GeneratedColumn<bool>(
    'completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("completed" IN (0, 1))',
    ),
  );
  static const VerificationMeta _auraMeta = const VerificationMeta('aura');
  @override
  late final GeneratedColumn<int> aura = GeneratedColumn<int>(
    'aura',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _modeMeta = const VerificationMeta('mode');
  @override
  late final GeneratedColumn<String> mode = GeneratedColumn<String>(
    'mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('solo'),
  );
  static const VerificationMeta _vibeMeta = const VerificationMeta('vibe');
  @override
  late final GeneratedColumn<String> vibe = GeneratedColumn<String>(
    'vibe',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('study'),
  );
  static const VerificationMeta _clutchesMeta = const VerificationMeta(
    'clutches',
  );
  @override
  late final GeneratedColumn<int> clutches = GeneratedColumn<int>(
    'clutches',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _passUsedMeta = const VerificationMeta(
    'passUsed',
  );
  @override
  late final GeneratedColumn<bool> passUsed = GeneratedColumn<bool>(
    'pass_used',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("pass_used" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _groupSizeMeta = const VerificationMeta(
    'groupSize',
  );
  @override
  late final GeneratedColumn<int> groupSize = GeneratedColumn<int>(
    'group_size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _squadCleanMeta = const VerificationMeta(
    'squadClean',
  );
  @override
  late final GeneratedColumn<bool> squadClean = GeneratedColumn<bool>(
    'squad_clean',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("squad_clean" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _wonMeta = const VerificationMeta('won');
  @override
  late final GeneratedColumn<bool> won = GeneratedColumn<bool>(
    'won',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("won" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _questAuraMeta = const VerificationMeta(
    'questAura',
  );
  @override
  late final GeneratedColumn<int> questAura = GeneratedColumn<int>(
    'quest_aura',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    startedAt,
    endedAt,
    plannedMinutes,
    lockedSeconds,
    cracks,
    completed,
    aura,
    mode,
    vibe,
    clutches,
    passUsed,
    groupSize,
    squadClean,
    won,
    questAura,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<SessionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('ended_at')) {
      context.handle(
        _endedAtMeta,
        endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_endedAtMeta);
    }
    if (data.containsKey('planned_minutes')) {
      context.handle(
        _plannedMinutesMeta,
        plannedMinutes.isAcceptableOrUnknown(
          data['planned_minutes']!,
          _plannedMinutesMeta,
        ),
      );
    }
    if (data.containsKey('locked_seconds')) {
      context.handle(
        _lockedSecondsMeta,
        lockedSeconds.isAcceptableOrUnknown(
          data['locked_seconds']!,
          _lockedSecondsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lockedSecondsMeta);
    }
    if (data.containsKey('cracks')) {
      context.handle(
        _cracksMeta,
        cracks.isAcceptableOrUnknown(data['cracks']!, _cracksMeta),
      );
    } else if (isInserting) {
      context.missing(_cracksMeta);
    }
    if (data.containsKey('completed')) {
      context.handle(
        _completedMeta,
        completed.isAcceptableOrUnknown(data['completed']!, _completedMeta),
      );
    } else if (isInserting) {
      context.missing(_completedMeta);
    }
    if (data.containsKey('aura')) {
      context.handle(
        _auraMeta,
        aura.isAcceptableOrUnknown(data['aura']!, _auraMeta),
      );
    } else if (isInserting) {
      context.missing(_auraMeta);
    }
    if (data.containsKey('mode')) {
      context.handle(
        _modeMeta,
        mode.isAcceptableOrUnknown(data['mode']!, _modeMeta),
      );
    }
    if (data.containsKey('vibe')) {
      context.handle(
        _vibeMeta,
        vibe.isAcceptableOrUnknown(data['vibe']!, _vibeMeta),
      );
    }
    if (data.containsKey('clutches')) {
      context.handle(
        _clutchesMeta,
        clutches.isAcceptableOrUnknown(data['clutches']!, _clutchesMeta),
      );
    }
    if (data.containsKey('pass_used')) {
      context.handle(
        _passUsedMeta,
        passUsed.isAcceptableOrUnknown(data['pass_used']!, _passUsedMeta),
      );
    }
    if (data.containsKey('group_size')) {
      context.handle(
        _groupSizeMeta,
        groupSize.isAcceptableOrUnknown(data['group_size']!, _groupSizeMeta),
      );
    }
    if (data.containsKey('squad_clean')) {
      context.handle(
        _squadCleanMeta,
        squadClean.isAcceptableOrUnknown(data['squad_clean']!, _squadCleanMeta),
      );
    }
    if (data.containsKey('won')) {
      context.handle(
        _wonMeta,
        won.isAcceptableOrUnknown(data['won']!, _wonMeta),
      );
    }
    if (data.containsKey('quest_aura')) {
      context.handle(
        _questAuraMeta,
        questAura.isAcceptableOrUnknown(data['quest_aura']!, _questAuraMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SessionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SessionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      endedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ended_at'],
      )!,
      plannedMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}planned_minutes'],
      ),
      lockedSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}locked_seconds'],
      )!,
      cracks: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cracks'],
      )!,
      completed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}completed'],
      )!,
      aura: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}aura'],
      )!,
      mode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mode'],
      )!,
      vibe: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}vibe'],
      )!,
      clutches: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}clutches'],
      )!,
      passUsed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}pass_used'],
      )!,
      groupSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}group_size'],
      )!,
      squadClean: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}squad_clean'],
      )!,
      won: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}won'],
      )!,
      questAura: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quest_aura'],
      )!,
    );
  }

  @override
  $SessionsTable createAlias(String alias) {
    return $SessionsTable(attachedDatabase, alias);
  }
}

class SessionRow extends DataClass implements Insertable<SessionRow> {
  final int id;
  final DateTime startedAt;
  final DateTime endedAt;

  /// Null for open-ended sessions.
  final int? plannedMinutes;
  final int lockedSeconds;
  final int cracks;
  final bool completed;
  final int aura;

  /// solo | group | migrated
  final String mode;
  final String vibe;
  final int clutches;
  final bool passUsed;
  final int groupSize;
  final bool squadClean;
  final bool won;
  final int questAura;
  const SessionRow({
    required this.id,
    required this.startedAt,
    required this.endedAt,
    this.plannedMinutes,
    required this.lockedSeconds,
    required this.cracks,
    required this.completed,
    required this.aura,
    required this.mode,
    required this.vibe,
    required this.clutches,
    required this.passUsed,
    required this.groupSize,
    required this.squadClean,
    required this.won,
    required this.questAura,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['started_at'] = Variable<DateTime>(startedAt);
    map['ended_at'] = Variable<DateTime>(endedAt);
    if (!nullToAbsent || plannedMinutes != null) {
      map['planned_minutes'] = Variable<int>(plannedMinutes);
    }
    map['locked_seconds'] = Variable<int>(lockedSeconds);
    map['cracks'] = Variable<int>(cracks);
    map['completed'] = Variable<bool>(completed);
    map['aura'] = Variable<int>(aura);
    map['mode'] = Variable<String>(mode);
    map['vibe'] = Variable<String>(vibe);
    map['clutches'] = Variable<int>(clutches);
    map['pass_used'] = Variable<bool>(passUsed);
    map['group_size'] = Variable<int>(groupSize);
    map['squad_clean'] = Variable<bool>(squadClean);
    map['won'] = Variable<bool>(won);
    map['quest_aura'] = Variable<int>(questAura);
    return map;
  }

  SessionsCompanion toCompanion(bool nullToAbsent) {
    return SessionsCompanion(
      id: Value(id),
      startedAt: Value(startedAt),
      endedAt: Value(endedAt),
      plannedMinutes: plannedMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(plannedMinutes),
      lockedSeconds: Value(lockedSeconds),
      cracks: Value(cracks),
      completed: Value(completed),
      aura: Value(aura),
      mode: Value(mode),
      vibe: Value(vibe),
      clutches: Value(clutches),
      passUsed: Value(passUsed),
      groupSize: Value(groupSize),
      squadClean: Value(squadClean),
      won: Value(won),
      questAura: Value(questAura),
    );
  }

  factory SessionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SessionRow(
      id: serializer.fromJson<int>(json['id']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      endedAt: serializer.fromJson<DateTime>(json['endedAt']),
      plannedMinutes: serializer.fromJson<int?>(json['plannedMinutes']),
      lockedSeconds: serializer.fromJson<int>(json['lockedSeconds']),
      cracks: serializer.fromJson<int>(json['cracks']),
      completed: serializer.fromJson<bool>(json['completed']),
      aura: serializer.fromJson<int>(json['aura']),
      mode: serializer.fromJson<String>(json['mode']),
      vibe: serializer.fromJson<String>(json['vibe']),
      clutches: serializer.fromJson<int>(json['clutches']),
      passUsed: serializer.fromJson<bool>(json['passUsed']),
      groupSize: serializer.fromJson<int>(json['groupSize']),
      squadClean: serializer.fromJson<bool>(json['squadClean']),
      won: serializer.fromJson<bool>(json['won']),
      questAura: serializer.fromJson<int>(json['questAura']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'endedAt': serializer.toJson<DateTime>(endedAt),
      'plannedMinutes': serializer.toJson<int?>(plannedMinutes),
      'lockedSeconds': serializer.toJson<int>(lockedSeconds),
      'cracks': serializer.toJson<int>(cracks),
      'completed': serializer.toJson<bool>(completed),
      'aura': serializer.toJson<int>(aura),
      'mode': serializer.toJson<String>(mode),
      'vibe': serializer.toJson<String>(vibe),
      'clutches': serializer.toJson<int>(clutches),
      'passUsed': serializer.toJson<bool>(passUsed),
      'groupSize': serializer.toJson<int>(groupSize),
      'squadClean': serializer.toJson<bool>(squadClean),
      'won': serializer.toJson<bool>(won),
      'questAura': serializer.toJson<int>(questAura),
    };
  }

  SessionRow copyWith({
    int? id,
    DateTime? startedAt,
    DateTime? endedAt,
    Value<int?> plannedMinutes = const Value.absent(),
    int? lockedSeconds,
    int? cracks,
    bool? completed,
    int? aura,
    String? mode,
    String? vibe,
    int? clutches,
    bool? passUsed,
    int? groupSize,
    bool? squadClean,
    bool? won,
    int? questAura,
  }) => SessionRow(
    id: id ?? this.id,
    startedAt: startedAt ?? this.startedAt,
    endedAt: endedAt ?? this.endedAt,
    plannedMinutes: plannedMinutes.present
        ? plannedMinutes.value
        : this.plannedMinutes,
    lockedSeconds: lockedSeconds ?? this.lockedSeconds,
    cracks: cracks ?? this.cracks,
    completed: completed ?? this.completed,
    aura: aura ?? this.aura,
    mode: mode ?? this.mode,
    vibe: vibe ?? this.vibe,
    clutches: clutches ?? this.clutches,
    passUsed: passUsed ?? this.passUsed,
    groupSize: groupSize ?? this.groupSize,
    squadClean: squadClean ?? this.squadClean,
    won: won ?? this.won,
    questAura: questAura ?? this.questAura,
  );
  SessionRow copyWithCompanion(SessionsCompanion data) {
    return SessionRow(
      id: data.id.present ? data.id.value : this.id,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      plannedMinutes: data.plannedMinutes.present
          ? data.plannedMinutes.value
          : this.plannedMinutes,
      lockedSeconds: data.lockedSeconds.present
          ? data.lockedSeconds.value
          : this.lockedSeconds,
      cracks: data.cracks.present ? data.cracks.value : this.cracks,
      completed: data.completed.present ? data.completed.value : this.completed,
      aura: data.aura.present ? data.aura.value : this.aura,
      mode: data.mode.present ? data.mode.value : this.mode,
      vibe: data.vibe.present ? data.vibe.value : this.vibe,
      clutches: data.clutches.present ? data.clutches.value : this.clutches,
      passUsed: data.passUsed.present ? data.passUsed.value : this.passUsed,
      groupSize: data.groupSize.present ? data.groupSize.value : this.groupSize,
      squadClean: data.squadClean.present
          ? data.squadClean.value
          : this.squadClean,
      won: data.won.present ? data.won.value : this.won,
      questAura: data.questAura.present ? data.questAura.value : this.questAura,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SessionRow(')
          ..write('id: $id, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('plannedMinutes: $plannedMinutes, ')
          ..write('lockedSeconds: $lockedSeconds, ')
          ..write('cracks: $cracks, ')
          ..write('completed: $completed, ')
          ..write('aura: $aura, ')
          ..write('mode: $mode, ')
          ..write('vibe: $vibe, ')
          ..write('clutches: $clutches, ')
          ..write('passUsed: $passUsed, ')
          ..write('groupSize: $groupSize, ')
          ..write('squadClean: $squadClean, ')
          ..write('won: $won, ')
          ..write('questAura: $questAura')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    startedAt,
    endedAt,
    plannedMinutes,
    lockedSeconds,
    cracks,
    completed,
    aura,
    mode,
    vibe,
    clutches,
    passUsed,
    groupSize,
    squadClean,
    won,
    questAura,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SessionRow &&
          other.id == this.id &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt &&
          other.plannedMinutes == this.plannedMinutes &&
          other.lockedSeconds == this.lockedSeconds &&
          other.cracks == this.cracks &&
          other.completed == this.completed &&
          other.aura == this.aura &&
          other.mode == this.mode &&
          other.vibe == this.vibe &&
          other.clutches == this.clutches &&
          other.passUsed == this.passUsed &&
          other.groupSize == this.groupSize &&
          other.squadClean == this.squadClean &&
          other.won == this.won &&
          other.questAura == this.questAura);
}

class SessionsCompanion extends UpdateCompanion<SessionRow> {
  final Value<int> id;
  final Value<DateTime> startedAt;
  final Value<DateTime> endedAt;
  final Value<int?> plannedMinutes;
  final Value<int> lockedSeconds;
  final Value<int> cracks;
  final Value<bool> completed;
  final Value<int> aura;
  final Value<String> mode;
  final Value<String> vibe;
  final Value<int> clutches;
  final Value<bool> passUsed;
  final Value<int> groupSize;
  final Value<bool> squadClean;
  final Value<bool> won;
  final Value<int> questAura;
  const SessionsCompanion({
    this.id = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.plannedMinutes = const Value.absent(),
    this.lockedSeconds = const Value.absent(),
    this.cracks = const Value.absent(),
    this.completed = const Value.absent(),
    this.aura = const Value.absent(),
    this.mode = const Value.absent(),
    this.vibe = const Value.absent(),
    this.clutches = const Value.absent(),
    this.passUsed = const Value.absent(),
    this.groupSize = const Value.absent(),
    this.squadClean = const Value.absent(),
    this.won = const Value.absent(),
    this.questAura = const Value.absent(),
  });
  SessionsCompanion.insert({
    this.id = const Value.absent(),
    required DateTime startedAt,
    required DateTime endedAt,
    this.plannedMinutes = const Value.absent(),
    required int lockedSeconds,
    required int cracks,
    required bool completed,
    required int aura,
    this.mode = const Value.absent(),
    this.vibe = const Value.absent(),
    this.clutches = const Value.absent(),
    this.passUsed = const Value.absent(),
    this.groupSize = const Value.absent(),
    this.squadClean = const Value.absent(),
    this.won = const Value.absent(),
    this.questAura = const Value.absent(),
  }) : startedAt = Value(startedAt),
       endedAt = Value(endedAt),
       lockedSeconds = Value(lockedSeconds),
       cracks = Value(cracks),
       completed = Value(completed),
       aura = Value(aura);
  static Insertable<SessionRow> custom({
    Expression<int>? id,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? endedAt,
    Expression<int>? plannedMinutes,
    Expression<int>? lockedSeconds,
    Expression<int>? cracks,
    Expression<bool>? completed,
    Expression<int>? aura,
    Expression<String>? mode,
    Expression<String>? vibe,
    Expression<int>? clutches,
    Expression<bool>? passUsed,
    Expression<int>? groupSize,
    Expression<bool>? squadClean,
    Expression<bool>? won,
    Expression<int>? questAura,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (plannedMinutes != null) 'planned_minutes': plannedMinutes,
      if (lockedSeconds != null) 'locked_seconds': lockedSeconds,
      if (cracks != null) 'cracks': cracks,
      if (completed != null) 'completed': completed,
      if (aura != null) 'aura': aura,
      if (mode != null) 'mode': mode,
      if (vibe != null) 'vibe': vibe,
      if (clutches != null) 'clutches': clutches,
      if (passUsed != null) 'pass_used': passUsed,
      if (groupSize != null) 'group_size': groupSize,
      if (squadClean != null) 'squad_clean': squadClean,
      if (won != null) 'won': won,
      if (questAura != null) 'quest_aura': questAura,
    });
  }

  SessionsCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? startedAt,
    Value<DateTime>? endedAt,
    Value<int?>? plannedMinutes,
    Value<int>? lockedSeconds,
    Value<int>? cracks,
    Value<bool>? completed,
    Value<int>? aura,
    Value<String>? mode,
    Value<String>? vibe,
    Value<int>? clutches,
    Value<bool>? passUsed,
    Value<int>? groupSize,
    Value<bool>? squadClean,
    Value<bool>? won,
    Value<int>? questAura,
  }) {
    return SessionsCompanion(
      id: id ?? this.id,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      plannedMinutes: plannedMinutes ?? this.plannedMinutes,
      lockedSeconds: lockedSeconds ?? this.lockedSeconds,
      cracks: cracks ?? this.cracks,
      completed: completed ?? this.completed,
      aura: aura ?? this.aura,
      mode: mode ?? this.mode,
      vibe: vibe ?? this.vibe,
      clutches: clutches ?? this.clutches,
      passUsed: passUsed ?? this.passUsed,
      groupSize: groupSize ?? this.groupSize,
      squadClean: squadClean ?? this.squadClean,
      won: won ?? this.won,
      questAura: questAura ?? this.questAura,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<DateTime>(endedAt.value);
    }
    if (plannedMinutes.present) {
      map['planned_minutes'] = Variable<int>(plannedMinutes.value);
    }
    if (lockedSeconds.present) {
      map['locked_seconds'] = Variable<int>(lockedSeconds.value);
    }
    if (cracks.present) {
      map['cracks'] = Variable<int>(cracks.value);
    }
    if (completed.present) {
      map['completed'] = Variable<bool>(completed.value);
    }
    if (aura.present) {
      map['aura'] = Variable<int>(aura.value);
    }
    if (mode.present) {
      map['mode'] = Variable<String>(mode.value);
    }
    if (vibe.present) {
      map['vibe'] = Variable<String>(vibe.value);
    }
    if (clutches.present) {
      map['clutches'] = Variable<int>(clutches.value);
    }
    if (passUsed.present) {
      map['pass_used'] = Variable<bool>(passUsed.value);
    }
    if (groupSize.present) {
      map['group_size'] = Variable<int>(groupSize.value);
    }
    if (squadClean.present) {
      map['squad_clean'] = Variable<bool>(squadClean.value);
    }
    if (won.present) {
      map['won'] = Variable<bool>(won.value);
    }
    if (questAura.present) {
      map['quest_aura'] = Variable<int>(questAura.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SessionsCompanion(')
          ..write('id: $id, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('plannedMinutes: $plannedMinutes, ')
          ..write('lockedSeconds: $lockedSeconds, ')
          ..write('cracks: $cracks, ')
          ..write('completed: $completed, ')
          ..write('aura: $aura, ')
          ..write('mode: $mode, ')
          ..write('vibe: $vibe, ')
          ..write('clutches: $clutches, ')
          ..write('passUsed: $passUsed, ')
          ..write('groupSize: $groupSize, ')
          ..write('squadClean: $squadClean, ')
          ..write('won: $won, ')
          ..write('questAura: $questAura')
          ..write(')'))
        .toString();
  }
}

class $DailyActivityTable extends DailyActivity
    with TableInfo<$DailyActivityTable, DayRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DailyActivityTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<int> day = GeneratedColumn<int>(
    'day',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lockedSecondsMeta = const VerificationMeta(
    'lockedSeconds',
  );
  @override
  late final GeneratedColumn<int> lockedSeconds = GeneratedColumn<int>(
    'locked_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _auraMeta = const VerificationMeta('aura');
  @override
  late final GeneratedColumn<int> aura = GeneratedColumn<int>(
    'aura',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _qualifiedMeta = const VerificationMeta(
    'qualified',
  );
  @override
  late final GeneratedColumn<bool> qualified = GeneratedColumn<bool>(
    'qualified',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("qualified" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _frozenMeta = const VerificationMeta('frozen');
  @override
  late final GeneratedColumn<bool> frozen = GeneratedColumn<bool>(
    'frozen',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("frozen" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _questDoneMeta = const VerificationMeta(
    'questDone',
  );
  @override
  late final GeneratedColumn<bool> questDone = GeneratedColumn<bool>(
    'quest_done',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("quest_done" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    day,
    lockedSeconds,
    aura,
    qualified,
    frozen,
    questDone,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'daily_activity';
  @override
  VerificationContext validateIntegrity(
    Insertable<DayRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('day')) {
      context.handle(
        _dayMeta,
        day.isAcceptableOrUnknown(data['day']!, _dayMeta),
      );
    }
    if (data.containsKey('locked_seconds')) {
      context.handle(
        _lockedSecondsMeta,
        lockedSeconds.isAcceptableOrUnknown(
          data['locked_seconds']!,
          _lockedSecondsMeta,
        ),
      );
    }
    if (data.containsKey('aura')) {
      context.handle(
        _auraMeta,
        aura.isAcceptableOrUnknown(data['aura']!, _auraMeta),
      );
    }
    if (data.containsKey('qualified')) {
      context.handle(
        _qualifiedMeta,
        qualified.isAcceptableOrUnknown(data['qualified']!, _qualifiedMeta),
      );
    }
    if (data.containsKey('frozen')) {
      context.handle(
        _frozenMeta,
        frozen.isAcceptableOrUnknown(data['frozen']!, _frozenMeta),
      );
    }
    if (data.containsKey('quest_done')) {
      context.handle(
        _questDoneMeta,
        questDone.isAcceptableOrUnknown(data['quest_done']!, _questDoneMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {day};
  @override
  DayRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DayRow(
      day: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}day'],
      )!,
      lockedSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}locked_seconds'],
      )!,
      aura: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}aura'],
      )!,
      qualified: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}qualified'],
      )!,
      frozen: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}frozen'],
      )!,
      questDone: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}quest_done'],
      )!,
    );
  }

  @override
  $DailyActivityTable createAlias(String alias) {
    return $DailyActivityTable(attachedDatabase, alias);
  }
}

class DayRow extends DataClass implements Insertable<DayRow> {
  /// dayNumber (local calendar day).
  final int day;
  final int lockedSeconds;
  final int aura;
  final bool qualified;

  /// Missed day covered by a streak freeze.
  final bool frozen;
  final bool questDone;
  const DayRow({
    required this.day,
    required this.lockedSeconds,
    required this.aura,
    required this.qualified,
    required this.frozen,
    required this.questDone,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['day'] = Variable<int>(day);
    map['locked_seconds'] = Variable<int>(lockedSeconds);
    map['aura'] = Variable<int>(aura);
    map['qualified'] = Variable<bool>(qualified);
    map['frozen'] = Variable<bool>(frozen);
    map['quest_done'] = Variable<bool>(questDone);
    return map;
  }

  DailyActivityCompanion toCompanion(bool nullToAbsent) {
    return DailyActivityCompanion(
      day: Value(day),
      lockedSeconds: Value(lockedSeconds),
      aura: Value(aura),
      qualified: Value(qualified),
      frozen: Value(frozen),
      questDone: Value(questDone),
    );
  }

  factory DayRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DayRow(
      day: serializer.fromJson<int>(json['day']),
      lockedSeconds: serializer.fromJson<int>(json['lockedSeconds']),
      aura: serializer.fromJson<int>(json['aura']),
      qualified: serializer.fromJson<bool>(json['qualified']),
      frozen: serializer.fromJson<bool>(json['frozen']),
      questDone: serializer.fromJson<bool>(json['questDone']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'day': serializer.toJson<int>(day),
      'lockedSeconds': serializer.toJson<int>(lockedSeconds),
      'aura': serializer.toJson<int>(aura),
      'qualified': serializer.toJson<bool>(qualified),
      'frozen': serializer.toJson<bool>(frozen),
      'questDone': serializer.toJson<bool>(questDone),
    };
  }

  DayRow copyWith({
    int? day,
    int? lockedSeconds,
    int? aura,
    bool? qualified,
    bool? frozen,
    bool? questDone,
  }) => DayRow(
    day: day ?? this.day,
    lockedSeconds: lockedSeconds ?? this.lockedSeconds,
    aura: aura ?? this.aura,
    qualified: qualified ?? this.qualified,
    frozen: frozen ?? this.frozen,
    questDone: questDone ?? this.questDone,
  );
  DayRow copyWithCompanion(DailyActivityCompanion data) {
    return DayRow(
      day: data.day.present ? data.day.value : this.day,
      lockedSeconds: data.lockedSeconds.present
          ? data.lockedSeconds.value
          : this.lockedSeconds,
      aura: data.aura.present ? data.aura.value : this.aura,
      qualified: data.qualified.present ? data.qualified.value : this.qualified,
      frozen: data.frozen.present ? data.frozen.value : this.frozen,
      questDone: data.questDone.present ? data.questDone.value : this.questDone,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DayRow(')
          ..write('day: $day, ')
          ..write('lockedSeconds: $lockedSeconds, ')
          ..write('aura: $aura, ')
          ..write('qualified: $qualified, ')
          ..write('frozen: $frozen, ')
          ..write('questDone: $questDone')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(day, lockedSeconds, aura, qualified, frozen, questDone);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DayRow &&
          other.day == this.day &&
          other.lockedSeconds == this.lockedSeconds &&
          other.aura == this.aura &&
          other.qualified == this.qualified &&
          other.frozen == this.frozen &&
          other.questDone == this.questDone);
}

class DailyActivityCompanion extends UpdateCompanion<DayRow> {
  final Value<int> day;
  final Value<int> lockedSeconds;
  final Value<int> aura;
  final Value<bool> qualified;
  final Value<bool> frozen;
  final Value<bool> questDone;
  const DailyActivityCompanion({
    this.day = const Value.absent(),
    this.lockedSeconds = const Value.absent(),
    this.aura = const Value.absent(),
    this.qualified = const Value.absent(),
    this.frozen = const Value.absent(),
    this.questDone = const Value.absent(),
  });
  DailyActivityCompanion.insert({
    this.day = const Value.absent(),
    this.lockedSeconds = const Value.absent(),
    this.aura = const Value.absent(),
    this.qualified = const Value.absent(),
    this.frozen = const Value.absent(),
    this.questDone = const Value.absent(),
  });
  static Insertable<DayRow> custom({
    Expression<int>? day,
    Expression<int>? lockedSeconds,
    Expression<int>? aura,
    Expression<bool>? qualified,
    Expression<bool>? frozen,
    Expression<bool>? questDone,
  }) {
    return RawValuesInsertable({
      if (day != null) 'day': day,
      if (lockedSeconds != null) 'locked_seconds': lockedSeconds,
      if (aura != null) 'aura': aura,
      if (qualified != null) 'qualified': qualified,
      if (frozen != null) 'frozen': frozen,
      if (questDone != null) 'quest_done': questDone,
    });
  }

  DailyActivityCompanion copyWith({
    Value<int>? day,
    Value<int>? lockedSeconds,
    Value<int>? aura,
    Value<bool>? qualified,
    Value<bool>? frozen,
    Value<bool>? questDone,
  }) {
    return DailyActivityCompanion(
      day: day ?? this.day,
      lockedSeconds: lockedSeconds ?? this.lockedSeconds,
      aura: aura ?? this.aura,
      qualified: qualified ?? this.qualified,
      frozen: frozen ?? this.frozen,
      questDone: questDone ?? this.questDone,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (day.present) {
      map['day'] = Variable<int>(day.value);
    }
    if (lockedSeconds.present) {
      map['locked_seconds'] = Variable<int>(lockedSeconds.value);
    }
    if (aura.present) {
      map['aura'] = Variable<int>(aura.value);
    }
    if (qualified.present) {
      map['qualified'] = Variable<bool>(qualified.value);
    }
    if (frozen.present) {
      map['frozen'] = Variable<bool>(frozen.value);
    }
    if (questDone.present) {
      map['quest_done'] = Variable<bool>(questDone.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DailyActivityCompanion(')
          ..write('day: $day, ')
          ..write('lockedSeconds: $lockedSeconds, ')
          ..write('aura: $aura, ')
          ..write('qualified: $qualified, ')
          ..write('frozen: $frozen, ')
          ..write('questDone: $questDone')
          ..write(')'))
        .toString();
  }
}

class $StreakStatesTable extends StreakStates
    with TableInfo<$StreakStatesTable, StreakRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StreakStatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _currentMeta = const VerificationMeta(
    'current',
  );
  @override
  late final GeneratedColumn<int> current = GeneratedColumn<int>(
    'current',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _longestMeta = const VerificationMeta(
    'longest',
  );
  @override
  late final GeneratedColumn<int> longest = GeneratedColumn<int>(
    'longest',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _freezesMeta = const VerificationMeta(
    'freezes',
  );
  @override
  late final GeneratedColumn<int> freezes = GeneratedColumn<int>(
    'freezes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastDayMeta = const VerificationMeta(
    'lastDay',
  );
  @override
  late final GeneratedColumn<int> lastDay = GeneratedColumn<int>(
    'last_day',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    current,
    longest,
    freezes,
    lastDay,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'streak_states';
  @override
  VerificationContext validateIntegrity(
    Insertable<StreakRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('current')) {
      context.handle(
        _currentMeta,
        current.isAcceptableOrUnknown(data['current']!, _currentMeta),
      );
    }
    if (data.containsKey('longest')) {
      context.handle(
        _longestMeta,
        longest.isAcceptableOrUnknown(data['longest']!, _longestMeta),
      );
    }
    if (data.containsKey('freezes')) {
      context.handle(
        _freezesMeta,
        freezes.isAcceptableOrUnknown(data['freezes']!, _freezesMeta),
      );
    }
    if (data.containsKey('last_day')) {
      context.handle(
        _lastDayMeta,
        lastDay.isAcceptableOrUnknown(data['last_day']!, _lastDayMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StreakRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StreakRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      current: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}current'],
      )!,
      longest: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}longest'],
      )!,
      freezes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}freezes'],
      )!,
      lastDay: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_day'],
      ),
    );
  }

  @override
  $StreakStatesTable createAlias(String alias) {
    return $StreakStatesTable(attachedDatabase, alias);
  }
}

class StreakRow extends DataClass implements Insertable<StreakRow> {
  final int id;
  final int current;
  final int longest;
  final int freezes;
  final int? lastDay;
  const StreakRow({
    required this.id,
    required this.current,
    required this.longest,
    required this.freezes,
    this.lastDay,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['current'] = Variable<int>(current);
    map['longest'] = Variable<int>(longest);
    map['freezes'] = Variable<int>(freezes);
    if (!nullToAbsent || lastDay != null) {
      map['last_day'] = Variable<int>(lastDay);
    }
    return map;
  }

  StreakStatesCompanion toCompanion(bool nullToAbsent) {
    return StreakStatesCompanion(
      id: Value(id),
      current: Value(current),
      longest: Value(longest),
      freezes: Value(freezes),
      lastDay: lastDay == null && nullToAbsent
          ? const Value.absent()
          : Value(lastDay),
    );
  }

  factory StreakRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StreakRow(
      id: serializer.fromJson<int>(json['id']),
      current: serializer.fromJson<int>(json['current']),
      longest: serializer.fromJson<int>(json['longest']),
      freezes: serializer.fromJson<int>(json['freezes']),
      lastDay: serializer.fromJson<int?>(json['lastDay']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'current': serializer.toJson<int>(current),
      'longest': serializer.toJson<int>(longest),
      'freezes': serializer.toJson<int>(freezes),
      'lastDay': serializer.toJson<int?>(lastDay),
    };
  }

  StreakRow copyWith({
    int? id,
    int? current,
    int? longest,
    int? freezes,
    Value<int?> lastDay = const Value.absent(),
  }) => StreakRow(
    id: id ?? this.id,
    current: current ?? this.current,
    longest: longest ?? this.longest,
    freezes: freezes ?? this.freezes,
    lastDay: lastDay.present ? lastDay.value : this.lastDay,
  );
  StreakRow copyWithCompanion(StreakStatesCompanion data) {
    return StreakRow(
      id: data.id.present ? data.id.value : this.id,
      current: data.current.present ? data.current.value : this.current,
      longest: data.longest.present ? data.longest.value : this.longest,
      freezes: data.freezes.present ? data.freezes.value : this.freezes,
      lastDay: data.lastDay.present ? data.lastDay.value : this.lastDay,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StreakRow(')
          ..write('id: $id, ')
          ..write('current: $current, ')
          ..write('longest: $longest, ')
          ..write('freezes: $freezes, ')
          ..write('lastDay: $lastDay')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, current, longest, freezes, lastDay);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StreakRow &&
          other.id == this.id &&
          other.current == this.current &&
          other.longest == this.longest &&
          other.freezes == this.freezes &&
          other.lastDay == this.lastDay);
}

class StreakStatesCompanion extends UpdateCompanion<StreakRow> {
  final Value<int> id;
  final Value<int> current;
  final Value<int> longest;
  final Value<int> freezes;
  final Value<int?> lastDay;
  const StreakStatesCompanion({
    this.id = const Value.absent(),
    this.current = const Value.absent(),
    this.longest = const Value.absent(),
    this.freezes = const Value.absent(),
    this.lastDay = const Value.absent(),
  });
  StreakStatesCompanion.insert({
    this.id = const Value.absent(),
    this.current = const Value.absent(),
    this.longest = const Value.absent(),
    this.freezes = const Value.absent(),
    this.lastDay = const Value.absent(),
  });
  static Insertable<StreakRow> custom({
    Expression<int>? id,
    Expression<int>? current,
    Expression<int>? longest,
    Expression<int>? freezes,
    Expression<int>? lastDay,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (current != null) 'current': current,
      if (longest != null) 'longest': longest,
      if (freezes != null) 'freezes': freezes,
      if (lastDay != null) 'last_day': lastDay,
    });
  }

  StreakStatesCompanion copyWith({
    Value<int>? id,
    Value<int>? current,
    Value<int>? longest,
    Value<int>? freezes,
    Value<int?>? lastDay,
  }) {
    return StreakStatesCompanion(
      id: id ?? this.id,
      current: current ?? this.current,
      longest: longest ?? this.longest,
      freezes: freezes ?? this.freezes,
      lastDay: lastDay ?? this.lastDay,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (current.present) {
      map['current'] = Variable<int>(current.value);
    }
    if (longest.present) {
      map['longest'] = Variable<int>(longest.value);
    }
    if (freezes.present) {
      map['freezes'] = Variable<int>(freezes.value);
    }
    if (lastDay.present) {
      map['last_day'] = Variable<int>(lastDay.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StreakStatesCompanion(')
          ..write('id: $id, ')
          ..write('current: $current, ')
          ..write('longest: $longest, ')
          ..write('freezes: $freezes, ')
          ..write('lastDay: $lastDay')
          ..write(')'))
        .toString();
  }
}

class $UnlockedSkinsTable extends UnlockedSkins
    with TableInfo<$UnlockedSkinsTable, SkinRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UnlockedSkinsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _skinIdMeta = const VerificationMeta('skinId');
  @override
  late final GeneratedColumn<int> skinId = GeneratedColumn<int>(
    'skin_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _unlockedAtMeta = const VerificationMeta(
    'unlockedAt',
  );
  @override
  late final GeneratedColumn<DateTime> unlockedAt = GeneratedColumn<DateTime>(
    'unlocked_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _seenMeta = const VerificationMeta('seen');
  @override
  late final GeneratedColumn<bool> seen = GeneratedColumn<bool>(
    'seen',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("seen" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [skinId, unlockedAt, seen];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'unlocked_skins';
  @override
  VerificationContext validateIntegrity(
    Insertable<SkinRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('skin_id')) {
      context.handle(
        _skinIdMeta,
        skinId.isAcceptableOrUnknown(data['skin_id']!, _skinIdMeta),
      );
    }
    if (data.containsKey('unlocked_at')) {
      context.handle(
        _unlockedAtMeta,
        unlockedAt.isAcceptableOrUnknown(data['unlocked_at']!, _unlockedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_unlockedAtMeta);
    }
    if (data.containsKey('seen')) {
      context.handle(
        _seenMeta,
        seen.isAcceptableOrUnknown(data['seen']!, _seenMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {skinId};
  @override
  SkinRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SkinRow(
      skinId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}skin_id'],
      )!,
      unlockedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}unlocked_at'],
      )!,
      seen: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}seen'],
      )!,
    );
  }

  @override
  $UnlockedSkinsTable createAlias(String alias) {
    return $UnlockedSkinsTable(attachedDatabase, alias);
  }
}

class SkinRow extends DataClass implements Insertable<SkinRow> {
  final int skinId;
  final DateTime unlockedAt;
  final bool seen;
  const SkinRow({
    required this.skinId,
    required this.unlockedAt,
    required this.seen,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['skin_id'] = Variable<int>(skinId);
    map['unlocked_at'] = Variable<DateTime>(unlockedAt);
    map['seen'] = Variable<bool>(seen);
    return map;
  }

  UnlockedSkinsCompanion toCompanion(bool nullToAbsent) {
    return UnlockedSkinsCompanion(
      skinId: Value(skinId),
      unlockedAt: Value(unlockedAt),
      seen: Value(seen),
    );
  }

  factory SkinRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SkinRow(
      skinId: serializer.fromJson<int>(json['skinId']),
      unlockedAt: serializer.fromJson<DateTime>(json['unlockedAt']),
      seen: serializer.fromJson<bool>(json['seen']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'skinId': serializer.toJson<int>(skinId),
      'unlockedAt': serializer.toJson<DateTime>(unlockedAt),
      'seen': serializer.toJson<bool>(seen),
    };
  }

  SkinRow copyWith({int? skinId, DateTime? unlockedAt, bool? seen}) => SkinRow(
    skinId: skinId ?? this.skinId,
    unlockedAt: unlockedAt ?? this.unlockedAt,
    seen: seen ?? this.seen,
  );
  SkinRow copyWithCompanion(UnlockedSkinsCompanion data) {
    return SkinRow(
      skinId: data.skinId.present ? data.skinId.value : this.skinId,
      unlockedAt: data.unlockedAt.present
          ? data.unlockedAt.value
          : this.unlockedAt,
      seen: data.seen.present ? data.seen.value : this.seen,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SkinRow(')
          ..write('skinId: $skinId, ')
          ..write('unlockedAt: $unlockedAt, ')
          ..write('seen: $seen')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(skinId, unlockedAt, seen);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SkinRow &&
          other.skinId == this.skinId &&
          other.unlockedAt == this.unlockedAt &&
          other.seen == this.seen);
}

class UnlockedSkinsCompanion extends UpdateCompanion<SkinRow> {
  final Value<int> skinId;
  final Value<DateTime> unlockedAt;
  final Value<bool> seen;
  const UnlockedSkinsCompanion({
    this.skinId = const Value.absent(),
    this.unlockedAt = const Value.absent(),
    this.seen = const Value.absent(),
  });
  UnlockedSkinsCompanion.insert({
    this.skinId = const Value.absent(),
    required DateTime unlockedAt,
    this.seen = const Value.absent(),
  }) : unlockedAt = Value(unlockedAt);
  static Insertable<SkinRow> custom({
    Expression<int>? skinId,
    Expression<DateTime>? unlockedAt,
    Expression<bool>? seen,
  }) {
    return RawValuesInsertable({
      if (skinId != null) 'skin_id': skinId,
      if (unlockedAt != null) 'unlocked_at': unlockedAt,
      if (seen != null) 'seen': seen,
    });
  }

  UnlockedSkinsCompanion copyWith({
    Value<int>? skinId,
    Value<DateTime>? unlockedAt,
    Value<bool>? seen,
  }) {
    return UnlockedSkinsCompanion(
      skinId: skinId ?? this.skinId,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      seen: seen ?? this.seen,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (skinId.present) {
      map['skin_id'] = Variable<int>(skinId.value);
    }
    if (unlockedAt.present) {
      map['unlocked_at'] = Variable<DateTime>(unlockedAt.value);
    }
    if (seen.present) {
      map['seen'] = Variable<bool>(seen.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UnlockedSkinsCompanion(')
          ..write('skinId: $skinId, ')
          ..write('unlockedAt: $unlockedAt, ')
          ..write('seen: $seen')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SessionsTable sessions = $SessionsTable(this);
  late final $DailyActivityTable dailyActivity = $DailyActivityTable(this);
  late final $StreakStatesTable streakStates = $StreakStatesTable(this);
  late final $UnlockedSkinsTable unlockedSkins = $UnlockedSkinsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    sessions,
    dailyActivity,
    streakStates,
    unlockedSkins,
  ];
}

typedef $$SessionsTableCreateCompanionBuilder = SessionsCompanion Function({
  Value<int> id,
  required DateTime startedAt,
  required DateTime endedAt,
  Value<int?> plannedMinutes,
  required int lockedSeconds,
  required int cracks,
  required bool completed,
  required int aura,
  Value<String> mode,
  Value<String> vibe,
  Value<int> clutches,
  Value<bool> passUsed,
  Value<int> groupSize,
  Value<bool> squadClean,
  Value<bool> won,
  Value<int> questAura,
});
typedef $$SessionsTableUpdateCompanionBuilder = SessionsCompanion Function({
  Value<int> id,
  Value<DateTime> startedAt,
  Value<DateTime> endedAt,
  Value<int?> plannedMinutes,
  Value<int> lockedSeconds,
  Value<int> cracks,
  Value<bool> completed,
  Value<int> aura,
  Value<String> mode,
  Value<String> vibe,
  Value<int> clutches,
  Value<bool> passUsed,
  Value<int> groupSize,
  Value<bool> squadClean,
  Value<bool> won,
  Value<int> questAura,
});

class $$SessionsTableFilterComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get plannedMinutes => $composableBuilder(
    column: $table.plannedMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lockedSeconds => $composableBuilder(
    column: $table.lockedSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cracks => $composableBuilder(
    column: $table.cracks,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get completed => $composableBuilder(
    column: $table.completed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get aura => $composableBuilder(
    column: $table.aura,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get vibe => $composableBuilder(
    column: $table.vibe,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get clutches => $composableBuilder(
    column: $table.clutches,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get passUsed => $composableBuilder(
    column: $table.passUsed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get groupSize => $composableBuilder(
    column: $table.groupSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get squadClean => $composableBuilder(
    column: $table.squadClean,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get won => $composableBuilder(
    column: $table.won,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get questAura => $composableBuilder(
    column: $table.questAura,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get plannedMinutes => $composableBuilder(
    column: $table.plannedMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lockedSeconds => $composableBuilder(
    column: $table.lockedSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cracks => $composableBuilder(
    column: $table.cracks,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get completed => $composableBuilder(
    column: $table.completed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get aura => $composableBuilder(
    column: $table.aura,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get vibe => $composableBuilder(
    column: $table.vibe,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get clutches => $composableBuilder(
    column: $table.clutches,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get passUsed => $composableBuilder(
    column: $table.passUsed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get groupSize => $composableBuilder(
    column: $table.groupSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get squadClean => $composableBuilder(
    column: $table.squadClean,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get won => $composableBuilder(
    column: $table.won,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get questAura => $composableBuilder(
    column: $table.questAura,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);

  GeneratedColumn<int> get plannedMinutes => $composableBuilder(
    column: $table.plannedMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lockedSeconds => $composableBuilder(
    column: $table.lockedSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<int> get cracks =>
      $composableBuilder(column: $table.cracks, builder: (column) => column);

  GeneratedColumn<bool> get completed =>
      $composableBuilder(column: $table.completed, builder: (column) => column);

  GeneratedColumn<int> get aura =>
      $composableBuilder(column: $table.aura, builder: (column) => column);

  GeneratedColumn<String> get mode =>
      $composableBuilder(column: $table.mode, builder: (column) => column);

  GeneratedColumn<String> get vibe =>
      $composableBuilder(column: $table.vibe, builder: (column) => column);

  GeneratedColumn<int> get clutches =>
      $composableBuilder(column: $table.clutches, builder: (column) => column);

  GeneratedColumn<bool> get passUsed =>
      $composableBuilder(column: $table.passUsed, builder: (column) => column);

  GeneratedColumn<int> get groupSize =>
      $composableBuilder(column: $table.groupSize, builder: (column) => column);

  GeneratedColumn<bool> get squadClean => $composableBuilder(
    column: $table.squadClean,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get won =>
      $composableBuilder(column: $table.won, builder: (column) => column);

  GeneratedColumn<int> get questAura =>
      $composableBuilder(column: $table.questAura, builder: (column) => column);
}

class $$SessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SessionsTable,
          SessionRow,
          $$SessionsTableFilterComposer,
          $$SessionsTableOrderingComposer,
          $$SessionsTableAnnotationComposer,
          $$SessionsTableCreateCompanionBuilder,
          $$SessionsTableUpdateCompanionBuilder,
          (
            SessionRow,
            BaseReferences<_$AppDatabase, $SessionsTable, SessionRow>,
          ),
          SessionRow,
          PrefetchHooks Function()
        > {
  $$SessionsTableTableManager(_$AppDatabase db, $SessionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime> endedAt = const Value.absent(),
                Value<int?> plannedMinutes = const Value.absent(),
                Value<int> lockedSeconds = const Value.absent(),
                Value<int> cracks = const Value.absent(),
                Value<bool> completed = const Value.absent(),
                Value<int> aura = const Value.absent(),
                Value<String> mode = const Value.absent(),
                Value<String> vibe = const Value.absent(),
                Value<int> clutches = const Value.absent(),
                Value<bool> passUsed = const Value.absent(),
                Value<int> groupSize = const Value.absent(),
                Value<bool> squadClean = const Value.absent(),
                Value<bool> won = const Value.absent(),
                Value<int> questAura = const Value.absent(),
              }) => SessionsCompanion(
                id: id,
                startedAt: startedAt,
                endedAt: endedAt,
                plannedMinutes: plannedMinutes,
                lockedSeconds: lockedSeconds,
                cracks: cracks,
                completed: completed,
                aura: aura,
                mode: mode,
                vibe: vibe,
                clutches: clutches,
                passUsed: passUsed,
                groupSize: groupSize,
                squadClean: squadClean,
                won: won,
                questAura: questAura,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime startedAt,
                required DateTime endedAt,
                Value<int?> plannedMinutes = const Value.absent(),
                required int lockedSeconds,
                required int cracks,
                required bool completed,
                required int aura,
                Value<String> mode = const Value.absent(),
                Value<String> vibe = const Value.absent(),
                Value<int> clutches = const Value.absent(),
                Value<bool> passUsed = const Value.absent(),
                Value<int> groupSize = const Value.absent(),
                Value<bool> squadClean = const Value.absent(),
                Value<bool> won = const Value.absent(),
                Value<int> questAura = const Value.absent(),
              }) => SessionsCompanion.insert(
                id: id,
                startedAt: startedAt,
                endedAt: endedAt,
                plannedMinutes: plannedMinutes,
                lockedSeconds: lockedSeconds,
                cracks: cracks,
                completed: completed,
                aura: aura,
                mode: mode,
                vibe: vibe,
                clutches: clutches,
                passUsed: passUsed,
                groupSize: groupSize,
                squadClean: squadClean,
                won: won,
                questAura: questAura,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SessionsTable, SessionRow>(table),
                  BaseReferences<_$AppDatabase, $SessionsTable, SessionRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SessionsTable,
      SessionRow,
      $$SessionsTableFilterComposer,
      $$SessionsTableOrderingComposer,
      $$SessionsTableAnnotationComposer,
      $$SessionsTableCreateCompanionBuilder,
      $$SessionsTableUpdateCompanionBuilder,
      (SessionRow, BaseReferences<_$AppDatabase, $SessionsTable, SessionRow>),
      SessionRow,
      PrefetchHooks Function()
    >;
typedef $$DailyActivityTableCreateCompanionBuilder =
    DailyActivityCompanion Function({
      Value<int> day,
      Value<int> lockedSeconds,
      Value<int> aura,
      Value<bool> qualified,
      Value<bool> frozen,
      Value<bool> questDone,
    });
typedef $$DailyActivityTableUpdateCompanionBuilder =
    DailyActivityCompanion Function({
      Value<int> day,
      Value<int> lockedSeconds,
      Value<int> aura,
      Value<bool> qualified,
      Value<bool> frozen,
      Value<bool> questDone,
    });

class $$DailyActivityTableFilterComposer
    extends Composer<_$AppDatabase, $DailyActivityTable> {
  $$DailyActivityTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lockedSeconds => $composableBuilder(
    column: $table.lockedSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get aura => $composableBuilder(
    column: $table.aura,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get qualified => $composableBuilder(
    column: $table.qualified,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get frozen => $composableBuilder(
    column: $table.frozen,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get questDone => $composableBuilder(
    column: $table.questDone,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DailyActivityTableOrderingComposer
    extends Composer<_$AppDatabase, $DailyActivityTable> {
  $$DailyActivityTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lockedSeconds => $composableBuilder(
    column: $table.lockedSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get aura => $composableBuilder(
    column: $table.aura,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get qualified => $composableBuilder(
    column: $table.qualified,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get frozen => $composableBuilder(
    column: $table.frozen,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get questDone => $composableBuilder(
    column: $table.questDone,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DailyActivityTableAnnotationComposer
    extends Composer<_$AppDatabase, $DailyActivityTable> {
  $$DailyActivityTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get day =>
      $composableBuilder(column: $table.day, builder: (column) => column);

  GeneratedColumn<int> get lockedSeconds => $composableBuilder(
    column: $table.lockedSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<int> get aura =>
      $composableBuilder(column: $table.aura, builder: (column) => column);

  GeneratedColumn<bool> get qualified =>
      $composableBuilder(column: $table.qualified, builder: (column) => column);

  GeneratedColumn<bool> get frozen =>
      $composableBuilder(column: $table.frozen, builder: (column) => column);

  GeneratedColumn<bool> get questDone =>
      $composableBuilder(column: $table.questDone, builder: (column) => column);
}

class $$DailyActivityTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DailyActivityTable,
          DayRow,
          $$DailyActivityTableFilterComposer,
          $$DailyActivityTableOrderingComposer,
          $$DailyActivityTableAnnotationComposer,
          $$DailyActivityTableCreateCompanionBuilder,
          $$DailyActivityTableUpdateCompanionBuilder,
          (DayRow, BaseReferences<_$AppDatabase, $DailyActivityTable, DayRow>),
          DayRow,
          PrefetchHooks Function()
        > {
  $$DailyActivityTableTableManager(_$AppDatabase db, $DailyActivityTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DailyActivityTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DailyActivityTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DailyActivityTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> day = const Value.absent(),
                Value<int> lockedSeconds = const Value.absent(),
                Value<int> aura = const Value.absent(),
                Value<bool> qualified = const Value.absent(),
                Value<bool> frozen = const Value.absent(),
                Value<bool> questDone = const Value.absent(),
              }) => DailyActivityCompanion(
                day: day,
                lockedSeconds: lockedSeconds,
                aura: aura,
                qualified: qualified,
                frozen: frozen,
                questDone: questDone,
              ),
          createCompanionCallback:
              ({
                Value<int> day = const Value.absent(),
                Value<int> lockedSeconds = const Value.absent(),
                Value<int> aura = const Value.absent(),
                Value<bool> qualified = const Value.absent(),
                Value<bool> frozen = const Value.absent(),
                Value<bool> questDone = const Value.absent(),
              }) => DailyActivityCompanion.insert(
                day: day,
                lockedSeconds: lockedSeconds,
                aura: aura,
                qualified: qualified,
                frozen: frozen,
                questDone: questDone,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DailyActivityTable, DayRow>(table),
                  BaseReferences<_$AppDatabase, $DailyActivityTable, DayRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DailyActivityTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DailyActivityTable,
      DayRow,
      $$DailyActivityTableFilterComposer,
      $$DailyActivityTableOrderingComposer,
      $$DailyActivityTableAnnotationComposer,
      $$DailyActivityTableCreateCompanionBuilder,
      $$DailyActivityTableUpdateCompanionBuilder,
      (DayRow, BaseReferences<_$AppDatabase, $DailyActivityTable, DayRow>),
      DayRow,
      PrefetchHooks Function()
    >;
typedef $$StreakStatesTableCreateCompanionBuilder =
    StreakStatesCompanion Function({
      Value<int> id,
      Value<int> current,
      Value<int> longest,
      Value<int> freezes,
      Value<int?> lastDay,
    });
typedef $$StreakStatesTableUpdateCompanionBuilder =
    StreakStatesCompanion Function({
      Value<int> id,
      Value<int> current,
      Value<int> longest,
      Value<int> freezes,
      Value<int?> lastDay,
    });

class $$StreakStatesTableFilterComposer
    extends Composer<_$AppDatabase, $StreakStatesTable> {
  $$StreakStatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get current => $composableBuilder(
    column: $table.current,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get longest => $composableBuilder(
    column: $table.longest,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get freezes => $composableBuilder(
    column: $table.freezes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastDay => $composableBuilder(
    column: $table.lastDay,
    builder: (column) => ColumnFilters(column),
  );
}

class $$StreakStatesTableOrderingComposer
    extends Composer<_$AppDatabase, $StreakStatesTable> {
  $$StreakStatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get current => $composableBuilder(
    column: $table.current,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get longest => $composableBuilder(
    column: $table.longest,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get freezes => $composableBuilder(
    column: $table.freezes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastDay => $composableBuilder(
    column: $table.lastDay,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StreakStatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $StreakStatesTable> {
  $$StreakStatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get current =>
      $composableBuilder(column: $table.current, builder: (column) => column);

  GeneratedColumn<int> get longest =>
      $composableBuilder(column: $table.longest, builder: (column) => column);

  GeneratedColumn<int> get freezes =>
      $composableBuilder(column: $table.freezes, builder: (column) => column);

  GeneratedColumn<int> get lastDay =>
      $composableBuilder(column: $table.lastDay, builder: (column) => column);
}

class $$StreakStatesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StreakStatesTable,
          StreakRow,
          $$StreakStatesTableFilterComposer,
          $$StreakStatesTableOrderingComposer,
          $$StreakStatesTableAnnotationComposer,
          $$StreakStatesTableCreateCompanionBuilder,
          $$StreakStatesTableUpdateCompanionBuilder,
          (
            StreakRow,
            BaseReferences<_$AppDatabase, $StreakStatesTable, StreakRow>,
          ),
          StreakRow,
          PrefetchHooks Function()
        > {
  $$StreakStatesTableTableManager(_$AppDatabase db, $StreakStatesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StreakStatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StreakStatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StreakStatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> current = const Value.absent(),
                Value<int> longest = const Value.absent(),
                Value<int> freezes = const Value.absent(),
                Value<int?> lastDay = const Value.absent(),
              }) => StreakStatesCompanion(
                id: id,
                current: current,
                longest: longest,
                freezes: freezes,
                lastDay: lastDay,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> current = const Value.absent(),
                Value<int> longest = const Value.absent(),
                Value<int> freezes = const Value.absent(),
                Value<int?> lastDay = const Value.absent(),
              }) => StreakStatesCompanion.insert(
                id: id,
                current: current,
                longest: longest,
                freezes: freezes,
                lastDay: lastDay,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$StreakStatesTable, StreakRow>(table),
                  BaseReferences<_$AppDatabase, $StreakStatesTable, StreakRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$StreakStatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StreakStatesTable,
      StreakRow,
      $$StreakStatesTableFilterComposer,
      $$StreakStatesTableOrderingComposer,
      $$StreakStatesTableAnnotationComposer,
      $$StreakStatesTableCreateCompanionBuilder,
      $$StreakStatesTableUpdateCompanionBuilder,
      (StreakRow, BaseReferences<_$AppDatabase, $StreakStatesTable, StreakRow>),
      StreakRow,
      PrefetchHooks Function()
    >;
typedef $$UnlockedSkinsTableCreateCompanionBuilder =
    UnlockedSkinsCompanion Function({
      Value<int> skinId,
      required DateTime unlockedAt,
      Value<bool> seen,
    });
typedef $$UnlockedSkinsTableUpdateCompanionBuilder =
    UnlockedSkinsCompanion Function({
      Value<int> skinId,
      Value<DateTime> unlockedAt,
      Value<bool> seen,
    });

class $$UnlockedSkinsTableFilterComposer
    extends Composer<_$AppDatabase, $UnlockedSkinsTable> {
  $$UnlockedSkinsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get skinId => $composableBuilder(
    column: $table.skinId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get unlockedAt => $composableBuilder(
    column: $table.unlockedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get seen => $composableBuilder(
    column: $table.seen,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UnlockedSkinsTableOrderingComposer
    extends Composer<_$AppDatabase, $UnlockedSkinsTable> {
  $$UnlockedSkinsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get skinId => $composableBuilder(
    column: $table.skinId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get unlockedAt => $composableBuilder(
    column: $table.unlockedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get seen => $composableBuilder(
    column: $table.seen,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UnlockedSkinsTableAnnotationComposer
    extends Composer<_$AppDatabase, $UnlockedSkinsTable> {
  $$UnlockedSkinsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get skinId =>
      $composableBuilder(column: $table.skinId, builder: (column) => column);

  GeneratedColumn<DateTime> get unlockedAt => $composableBuilder(
    column: $table.unlockedAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get seen =>
      $composableBuilder(column: $table.seen, builder: (column) => column);
}

class $$UnlockedSkinsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UnlockedSkinsTable,
          SkinRow,
          $$UnlockedSkinsTableFilterComposer,
          $$UnlockedSkinsTableOrderingComposer,
          $$UnlockedSkinsTableAnnotationComposer,
          $$UnlockedSkinsTableCreateCompanionBuilder,
          $$UnlockedSkinsTableUpdateCompanionBuilder,
          (
            SkinRow,
            BaseReferences<_$AppDatabase, $UnlockedSkinsTable, SkinRow>,
          ),
          SkinRow,
          PrefetchHooks Function()
        > {
  $$UnlockedSkinsTableTableManager(_$AppDatabase db, $UnlockedSkinsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UnlockedSkinsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UnlockedSkinsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UnlockedSkinsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> skinId = const Value.absent(),
                Value<DateTime> unlockedAt = const Value.absent(),
                Value<bool> seen = const Value.absent(),
              }) => UnlockedSkinsCompanion(
                skinId: skinId,
                unlockedAt: unlockedAt,
                seen: seen,
              ),
          createCompanionCallback:
              ({
                Value<int> skinId = const Value.absent(),
                required DateTime unlockedAt,
                Value<bool> seen = const Value.absent(),
              }) => UnlockedSkinsCompanion.insert(
                skinId: skinId,
                unlockedAt: unlockedAt,
                seen: seen,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$UnlockedSkinsTable, SkinRow>(table),
                  BaseReferences<_$AppDatabase, $UnlockedSkinsTable, SkinRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UnlockedSkinsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UnlockedSkinsTable,
      SkinRow,
      $$UnlockedSkinsTableFilterComposer,
      $$UnlockedSkinsTableOrderingComposer,
      $$UnlockedSkinsTableAnnotationComposer,
      $$UnlockedSkinsTableCreateCompanionBuilder,
      $$UnlockedSkinsTableUpdateCompanionBuilder,
      (SkinRow, BaseReferences<_$AppDatabase, $UnlockedSkinsTable, SkinRow>),
      SkinRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SessionsTableTableManager get sessions =>
      $$SessionsTableTableManager(_db, _db.sessions);
  $$DailyActivityTableTableManager get dailyActivity =>
      $$DailyActivityTableTableManager(_db, _db.dailyActivity);
  $$StreakStatesTableTableManager get streakStates =>
      $$StreakStatesTableTableManager(_db, _db.streakStates);
  $$UnlockedSkinsTableTableManager get unlockedSkins =>
      $$UnlockedSkinsTableTableManager(_db, _db.unlockedSkins);
}
