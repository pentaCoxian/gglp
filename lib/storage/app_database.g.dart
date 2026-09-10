// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ServersTable extends Servers with TableInfo<$ServersTable, ServerRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ServersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _hostMeta = const VerificationMeta('host');
  @override
  late final GeneratedColumn<String> host = GeneratedColumn<String>(
    'host',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _softwareNameMeta = const VerificationMeta(
    'softwareName',
  );
  @override
  late final GeneratedColumn<String> softwareName = GeneratedColumn<String>(
    'software_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _softwareVersionMeta = const VerificationMeta(
    'softwareVersion',
  );
  @override
  late final GeneratedColumn<String> softwareVersion = GeneratedColumn<String>(
    'software_version',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _iconUrlMeta = const VerificationMeta(
    'iconUrl',
  );
  @override
  late final GeneratedColumn<String> iconUrl = GeneratedColumn<String>(
    'icon_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bannerUrlMeta = const VerificationMeta(
    'bannerUrl',
  );
  @override
  late final GeneratedColumn<String> bannerUrl = GeneratedColumn<String>(
    'banner_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _metaFetchedAtMeta = const VerificationMeta(
    'metaFetchedAt',
  );
  @override
  late final GeneratedColumn<DateTime> metaFetchedAt =
      GeneratedColumn<DateTime>(
        'meta_fetched_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _rawJsonMeta = const VerificationMeta(
    'rawJson',
  );
  @override
  late final GeneratedColumn<String> rawJson = GeneratedColumn<String>(
    'raw_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    host,
    name,
    description,
    softwareName,
    softwareVersion,
    iconUrl,
    bannerUrl,
    metaFetchedAt,
    rawJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'servers';
  @override
  VerificationContext validateIntegrity(
    Insertable<ServerRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('host')) {
      context.handle(
        _hostMeta,
        host.isAcceptableOrUnknown(data['host']!, _hostMeta),
      );
    } else if (isInserting) {
      context.missing(_hostMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('software_name')) {
      context.handle(
        _softwareNameMeta,
        softwareName.isAcceptableOrUnknown(
          data['software_name']!,
          _softwareNameMeta,
        ),
      );
    }
    if (data.containsKey('software_version')) {
      context.handle(
        _softwareVersionMeta,
        softwareVersion.isAcceptableOrUnknown(
          data['software_version']!,
          _softwareVersionMeta,
        ),
      );
    }
    if (data.containsKey('icon_url')) {
      context.handle(
        _iconUrlMeta,
        iconUrl.isAcceptableOrUnknown(data['icon_url']!, _iconUrlMeta),
      );
    }
    if (data.containsKey('banner_url')) {
      context.handle(
        _bannerUrlMeta,
        bannerUrl.isAcceptableOrUnknown(data['banner_url']!, _bannerUrlMeta),
      );
    }
    if (data.containsKey('meta_fetched_at')) {
      context.handle(
        _metaFetchedAtMeta,
        metaFetchedAt.isAcceptableOrUnknown(
          data['meta_fetched_at']!,
          _metaFetchedAtMeta,
        ),
      );
    }
    if (data.containsKey('raw_json')) {
      context.handle(
        _rawJsonMeta,
        rawJson.isAcceptableOrUnknown(data['raw_json']!, _rawJsonMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {host};
  @override
  ServerRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ServerRow(
      host:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}host'],
          )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      ),
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      softwareName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}software_name'],
      ),
      softwareVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}software_version'],
      ),
      iconUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon_url'],
      ),
      bannerUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}banner_url'],
      ),
      metaFetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}meta_fetched_at'],
      ),
      rawJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}raw_json'],
      ),
    );
  }

  @override
  $ServersTable createAlias(String alias) {
    return $ServersTable(attachedDatabase, alias);
  }
}

class ServerRow extends DataClass implements Insertable<ServerRow> {
  final String host;
  final String? name;
  final String? description;
  final String? softwareName;
  final String? softwareVersion;
  final String? iconUrl;
  final String? bannerUrl;
  final DateTime? metaFetchedAt;
  final String? rawJson;
  const ServerRow({
    required this.host,
    this.name,
    this.description,
    this.softwareName,
    this.softwareVersion,
    this.iconUrl,
    this.bannerUrl,
    this.metaFetchedAt,
    this.rawJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['host'] = Variable<String>(host);
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || softwareName != null) {
      map['software_name'] = Variable<String>(softwareName);
    }
    if (!nullToAbsent || softwareVersion != null) {
      map['software_version'] = Variable<String>(softwareVersion);
    }
    if (!nullToAbsent || iconUrl != null) {
      map['icon_url'] = Variable<String>(iconUrl);
    }
    if (!nullToAbsent || bannerUrl != null) {
      map['banner_url'] = Variable<String>(bannerUrl);
    }
    if (!nullToAbsent || metaFetchedAt != null) {
      map['meta_fetched_at'] = Variable<DateTime>(metaFetchedAt);
    }
    if (!nullToAbsent || rawJson != null) {
      map['raw_json'] = Variable<String>(rawJson);
    }
    return map;
  }

  ServersCompanion toCompanion(bool nullToAbsent) {
    return ServersCompanion(
      host: Value(host),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      description:
          description == null && nullToAbsent
              ? const Value.absent()
              : Value(description),
      softwareName:
          softwareName == null && nullToAbsent
              ? const Value.absent()
              : Value(softwareName),
      softwareVersion:
          softwareVersion == null && nullToAbsent
              ? const Value.absent()
              : Value(softwareVersion),
      iconUrl:
          iconUrl == null && nullToAbsent
              ? const Value.absent()
              : Value(iconUrl),
      bannerUrl:
          bannerUrl == null && nullToAbsent
              ? const Value.absent()
              : Value(bannerUrl),
      metaFetchedAt:
          metaFetchedAt == null && nullToAbsent
              ? const Value.absent()
              : Value(metaFetchedAt),
      rawJson:
          rawJson == null && nullToAbsent
              ? const Value.absent()
              : Value(rawJson),
    );
  }

  factory ServerRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ServerRow(
      host: serializer.fromJson<String>(json['host']),
      name: serializer.fromJson<String?>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
      softwareName: serializer.fromJson<String?>(json['softwareName']),
      softwareVersion: serializer.fromJson<String?>(json['softwareVersion']),
      iconUrl: serializer.fromJson<String?>(json['iconUrl']),
      bannerUrl: serializer.fromJson<String?>(json['bannerUrl']),
      metaFetchedAt: serializer.fromJson<DateTime?>(json['metaFetchedAt']),
      rawJson: serializer.fromJson<String?>(json['rawJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'host': serializer.toJson<String>(host),
      'name': serializer.toJson<String?>(name),
      'description': serializer.toJson<String?>(description),
      'softwareName': serializer.toJson<String?>(softwareName),
      'softwareVersion': serializer.toJson<String?>(softwareVersion),
      'iconUrl': serializer.toJson<String?>(iconUrl),
      'bannerUrl': serializer.toJson<String?>(bannerUrl),
      'metaFetchedAt': serializer.toJson<DateTime?>(metaFetchedAt),
      'rawJson': serializer.toJson<String?>(rawJson),
    };
  }

  ServerRow copyWith({
    String? host,
    Value<String?> name = const Value.absent(),
    Value<String?> description = const Value.absent(),
    Value<String?> softwareName = const Value.absent(),
    Value<String?> softwareVersion = const Value.absent(),
    Value<String?> iconUrl = const Value.absent(),
    Value<String?> bannerUrl = const Value.absent(),
    Value<DateTime?> metaFetchedAt = const Value.absent(),
    Value<String?> rawJson = const Value.absent(),
  }) => ServerRow(
    host: host ?? this.host,
    name: name.present ? name.value : this.name,
    description: description.present ? description.value : this.description,
    softwareName: softwareName.present ? softwareName.value : this.softwareName,
    softwareVersion:
        softwareVersion.present ? softwareVersion.value : this.softwareVersion,
    iconUrl: iconUrl.present ? iconUrl.value : this.iconUrl,
    bannerUrl: bannerUrl.present ? bannerUrl.value : this.bannerUrl,
    metaFetchedAt:
        metaFetchedAt.present ? metaFetchedAt.value : this.metaFetchedAt,
    rawJson: rawJson.present ? rawJson.value : this.rawJson,
  );
  ServerRow copyWithCompanion(ServersCompanion data) {
    return ServerRow(
      host: data.host.present ? data.host.value : this.host,
      name: data.name.present ? data.name.value : this.name,
      description:
          data.description.present ? data.description.value : this.description,
      softwareName:
          data.softwareName.present
              ? data.softwareName.value
              : this.softwareName,
      softwareVersion:
          data.softwareVersion.present
              ? data.softwareVersion.value
              : this.softwareVersion,
      iconUrl: data.iconUrl.present ? data.iconUrl.value : this.iconUrl,
      bannerUrl: data.bannerUrl.present ? data.bannerUrl.value : this.bannerUrl,
      metaFetchedAt:
          data.metaFetchedAt.present
              ? data.metaFetchedAt.value
              : this.metaFetchedAt,
      rawJson: data.rawJson.present ? data.rawJson.value : this.rawJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ServerRow(')
          ..write('host: $host, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('softwareName: $softwareName, ')
          ..write('softwareVersion: $softwareVersion, ')
          ..write('iconUrl: $iconUrl, ')
          ..write('bannerUrl: $bannerUrl, ')
          ..write('metaFetchedAt: $metaFetchedAt, ')
          ..write('rawJson: $rawJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    host,
    name,
    description,
    softwareName,
    softwareVersion,
    iconUrl,
    bannerUrl,
    metaFetchedAt,
    rawJson,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ServerRow &&
          other.host == this.host &&
          other.name == this.name &&
          other.description == this.description &&
          other.softwareName == this.softwareName &&
          other.softwareVersion == this.softwareVersion &&
          other.iconUrl == this.iconUrl &&
          other.bannerUrl == this.bannerUrl &&
          other.metaFetchedAt == this.metaFetchedAt &&
          other.rawJson == this.rawJson);
}

class ServersCompanion extends UpdateCompanion<ServerRow> {
  final Value<String> host;
  final Value<String?> name;
  final Value<String?> description;
  final Value<String?> softwareName;
  final Value<String?> softwareVersion;
  final Value<String?> iconUrl;
  final Value<String?> bannerUrl;
  final Value<DateTime?> metaFetchedAt;
  final Value<String?> rawJson;
  final Value<int> rowid;
  const ServersCompanion({
    this.host = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.softwareName = const Value.absent(),
    this.softwareVersion = const Value.absent(),
    this.iconUrl = const Value.absent(),
    this.bannerUrl = const Value.absent(),
    this.metaFetchedAt = const Value.absent(),
    this.rawJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ServersCompanion.insert({
    required String host,
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.softwareName = const Value.absent(),
    this.softwareVersion = const Value.absent(),
    this.iconUrl = const Value.absent(),
    this.bannerUrl = const Value.absent(),
    this.metaFetchedAt = const Value.absent(),
    this.rawJson = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : host = Value(host);
  static Insertable<ServerRow> custom({
    Expression<String>? host,
    Expression<String>? name,
    Expression<String>? description,
    Expression<String>? softwareName,
    Expression<String>? softwareVersion,
    Expression<String>? iconUrl,
    Expression<String>? bannerUrl,
    Expression<DateTime>? metaFetchedAt,
    Expression<String>? rawJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (host != null) 'host': host,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (softwareName != null) 'software_name': softwareName,
      if (softwareVersion != null) 'software_version': softwareVersion,
      if (iconUrl != null) 'icon_url': iconUrl,
      if (bannerUrl != null) 'banner_url': bannerUrl,
      if (metaFetchedAt != null) 'meta_fetched_at': metaFetchedAt,
      if (rawJson != null) 'raw_json': rawJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ServersCompanion copyWith({
    Value<String>? host,
    Value<String?>? name,
    Value<String?>? description,
    Value<String?>? softwareName,
    Value<String?>? softwareVersion,
    Value<String?>? iconUrl,
    Value<String?>? bannerUrl,
    Value<DateTime?>? metaFetchedAt,
    Value<String?>? rawJson,
    Value<int>? rowid,
  }) {
    return ServersCompanion(
      host: host ?? this.host,
      name: name ?? this.name,
      description: description ?? this.description,
      softwareName: softwareName ?? this.softwareName,
      softwareVersion: softwareVersion ?? this.softwareVersion,
      iconUrl: iconUrl ?? this.iconUrl,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      metaFetchedAt: metaFetchedAt ?? this.metaFetchedAt,
      rawJson: rawJson ?? this.rawJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (host.present) {
      map['host'] = Variable<String>(host.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (softwareName.present) {
      map['software_name'] = Variable<String>(softwareName.value);
    }
    if (softwareVersion.present) {
      map['software_version'] = Variable<String>(softwareVersion.value);
    }
    if (iconUrl.present) {
      map['icon_url'] = Variable<String>(iconUrl.value);
    }
    if (bannerUrl.present) {
      map['banner_url'] = Variable<String>(bannerUrl.value);
    }
    if (metaFetchedAt.present) {
      map['meta_fetched_at'] = Variable<DateTime>(metaFetchedAt.value);
    }
    if (rawJson.present) {
      map['raw_json'] = Variable<String>(rawJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ServersCompanion(')
          ..write('host: $host, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('softwareName: $softwareName, ')
          ..write('softwareVersion: $softwareVersion, ')
          ..write('iconUrl: $iconUrl, ')
          ..write('bannerUrl: $bannerUrl, ')
          ..write('metaFetchedAt: $metaFetchedAt, ')
          ..write('rawJson: $rawJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AccountsTable extends Accounts
    with TableInfo<$AccountsTable, AccountRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AccountsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hostMeta = const VerificationMeta('host');
  @override
  late final GeneratedColumn<String> host = GeneratedColumn<String>(
    'host',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _usernameMeta = const VerificationMeta(
    'username',
  );
  @override
  late final GeneratedColumn<String> username = GeneratedColumn<String>(
    'username',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _avatarUrlMeta = const VerificationMeta(
    'avatarUrl',
  );
  @override
  late final GeneratedColumn<String> avatarUrl = GeneratedColumn<String>(
    'avatar_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isCatMeta = const VerificationMeta('isCat');
  @override
  late final GeneratedColumn<bool> isCat = GeneratedColumn<bool>(
    'is_cat',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_cat" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isAdminMeta = const VerificationMeta(
    'isAdmin',
  );
  @override
  late final GeneratedColumn<bool> isAdmin = GeneratedColumn<bool>(
    'is_admin',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_admin" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _addedAtMeta = const VerificationMeta(
    'addedAt',
  );
  @override
  late final GeneratedColumn<DateTime> addedAt = GeneratedColumn<DateTime>(
    'added_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastUsedAtMeta = const VerificationMeta(
    'lastUsedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastUsedAt = GeneratedColumn<DateTime>(
    'last_used_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    host,
    userId,
    username,
    displayName,
    avatarUrl,
    isCat,
    isAdmin,
    addedAt,
    lastUsedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'accounts';
  @override
  VerificationContext validateIntegrity(
    Insertable<AccountRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('host')) {
      context.handle(
        _hostMeta,
        host.isAcceptableOrUnknown(data['host']!, _hostMeta),
      );
    } else if (isInserting) {
      context.missing(_hostMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('username')) {
      context.handle(
        _usernameMeta,
        username.isAcceptableOrUnknown(data['username']!, _usernameMeta),
      );
    } else if (isInserting) {
      context.missing(_usernameMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    }
    if (data.containsKey('avatar_url')) {
      context.handle(
        _avatarUrlMeta,
        avatarUrl.isAcceptableOrUnknown(data['avatar_url']!, _avatarUrlMeta),
      );
    }
    if (data.containsKey('is_cat')) {
      context.handle(
        _isCatMeta,
        isCat.isAcceptableOrUnknown(data['is_cat']!, _isCatMeta),
      );
    }
    if (data.containsKey('is_admin')) {
      context.handle(
        _isAdminMeta,
        isAdmin.isAcceptableOrUnknown(data['is_admin']!, _isAdminMeta),
      );
    }
    if (data.containsKey('added_at')) {
      context.handle(
        _addedAtMeta,
        addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_addedAtMeta);
    }
    if (data.containsKey('last_used_at')) {
      context.handle(
        _lastUsedAtMeta,
        lastUsedAt.isAcceptableOrUnknown(
          data['last_used_at']!,
          _lastUsedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AccountRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AccountRow(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}id'],
          )!,
      host:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}host'],
          )!,
      userId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}user_id'],
          )!,
      username:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}username'],
          )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      ),
      avatarUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}avatar_url'],
      ),
      isCat:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}is_cat'],
          )!,
      isAdmin:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}is_admin'],
          )!,
      addedAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}added_at'],
          )!,
      lastUsedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_used_at'],
      ),
    );
  }

  @override
  $AccountsTable createAlias(String alias) {
    return $AccountsTable(attachedDatabase, alias);
  }
}

class AccountRow extends DataClass implements Insertable<AccountRow> {
  /// "host:userId"
  final String id;
  final String host;
  final String userId;
  final String username;
  final String? displayName;
  final String? avatarUrl;
  final bool isCat;
  final bool isAdmin;
  final DateTime addedAt;
  final DateTime? lastUsedAt;
  const AccountRow({
    required this.id,
    required this.host,
    required this.userId,
    required this.username,
    this.displayName,
    this.avatarUrl,
    required this.isCat,
    required this.isAdmin,
    required this.addedAt,
    this.lastUsedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['host'] = Variable<String>(host);
    map['user_id'] = Variable<String>(userId);
    map['username'] = Variable<String>(username);
    if (!nullToAbsent || displayName != null) {
      map['display_name'] = Variable<String>(displayName);
    }
    if (!nullToAbsent || avatarUrl != null) {
      map['avatar_url'] = Variable<String>(avatarUrl);
    }
    map['is_cat'] = Variable<bool>(isCat);
    map['is_admin'] = Variable<bool>(isAdmin);
    map['added_at'] = Variable<DateTime>(addedAt);
    if (!nullToAbsent || lastUsedAt != null) {
      map['last_used_at'] = Variable<DateTime>(lastUsedAt);
    }
    return map;
  }

  AccountsCompanion toCompanion(bool nullToAbsent) {
    return AccountsCompanion(
      id: Value(id),
      host: Value(host),
      userId: Value(userId),
      username: Value(username),
      displayName:
          displayName == null && nullToAbsent
              ? const Value.absent()
              : Value(displayName),
      avatarUrl:
          avatarUrl == null && nullToAbsent
              ? const Value.absent()
              : Value(avatarUrl),
      isCat: Value(isCat),
      isAdmin: Value(isAdmin),
      addedAt: Value(addedAt),
      lastUsedAt:
          lastUsedAt == null && nullToAbsent
              ? const Value.absent()
              : Value(lastUsedAt),
    );
  }

  factory AccountRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AccountRow(
      id: serializer.fromJson<String>(json['id']),
      host: serializer.fromJson<String>(json['host']),
      userId: serializer.fromJson<String>(json['userId']),
      username: serializer.fromJson<String>(json['username']),
      displayName: serializer.fromJson<String?>(json['displayName']),
      avatarUrl: serializer.fromJson<String?>(json['avatarUrl']),
      isCat: serializer.fromJson<bool>(json['isCat']),
      isAdmin: serializer.fromJson<bool>(json['isAdmin']),
      addedAt: serializer.fromJson<DateTime>(json['addedAt']),
      lastUsedAt: serializer.fromJson<DateTime?>(json['lastUsedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'host': serializer.toJson<String>(host),
      'userId': serializer.toJson<String>(userId),
      'username': serializer.toJson<String>(username),
      'displayName': serializer.toJson<String?>(displayName),
      'avatarUrl': serializer.toJson<String?>(avatarUrl),
      'isCat': serializer.toJson<bool>(isCat),
      'isAdmin': serializer.toJson<bool>(isAdmin),
      'addedAt': serializer.toJson<DateTime>(addedAt),
      'lastUsedAt': serializer.toJson<DateTime?>(lastUsedAt),
    };
  }

  AccountRow copyWith({
    String? id,
    String? host,
    String? userId,
    String? username,
    Value<String?> displayName = const Value.absent(),
    Value<String?> avatarUrl = const Value.absent(),
    bool? isCat,
    bool? isAdmin,
    DateTime? addedAt,
    Value<DateTime?> lastUsedAt = const Value.absent(),
  }) => AccountRow(
    id: id ?? this.id,
    host: host ?? this.host,
    userId: userId ?? this.userId,
    username: username ?? this.username,
    displayName: displayName.present ? displayName.value : this.displayName,
    avatarUrl: avatarUrl.present ? avatarUrl.value : this.avatarUrl,
    isCat: isCat ?? this.isCat,
    isAdmin: isAdmin ?? this.isAdmin,
    addedAt: addedAt ?? this.addedAt,
    lastUsedAt: lastUsedAt.present ? lastUsedAt.value : this.lastUsedAt,
  );
  AccountRow copyWithCompanion(AccountsCompanion data) {
    return AccountRow(
      id: data.id.present ? data.id.value : this.id,
      host: data.host.present ? data.host.value : this.host,
      userId: data.userId.present ? data.userId.value : this.userId,
      username: data.username.present ? data.username.value : this.username,
      displayName:
          data.displayName.present ? data.displayName.value : this.displayName,
      avatarUrl: data.avatarUrl.present ? data.avatarUrl.value : this.avatarUrl,
      isCat: data.isCat.present ? data.isCat.value : this.isCat,
      isAdmin: data.isAdmin.present ? data.isAdmin.value : this.isAdmin,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
      lastUsedAt:
          data.lastUsedAt.present ? data.lastUsedAt.value : this.lastUsedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AccountRow(')
          ..write('id: $id, ')
          ..write('host: $host, ')
          ..write('userId: $userId, ')
          ..write('username: $username, ')
          ..write('displayName: $displayName, ')
          ..write('avatarUrl: $avatarUrl, ')
          ..write('isCat: $isCat, ')
          ..write('isAdmin: $isAdmin, ')
          ..write('addedAt: $addedAt, ')
          ..write('lastUsedAt: $lastUsedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    host,
    userId,
    username,
    displayName,
    avatarUrl,
    isCat,
    isAdmin,
    addedAt,
    lastUsedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AccountRow &&
          other.id == this.id &&
          other.host == this.host &&
          other.userId == this.userId &&
          other.username == this.username &&
          other.displayName == this.displayName &&
          other.avatarUrl == this.avatarUrl &&
          other.isCat == this.isCat &&
          other.isAdmin == this.isAdmin &&
          other.addedAt == this.addedAt &&
          other.lastUsedAt == this.lastUsedAt);
}

class AccountsCompanion extends UpdateCompanion<AccountRow> {
  final Value<String> id;
  final Value<String> host;
  final Value<String> userId;
  final Value<String> username;
  final Value<String?> displayName;
  final Value<String?> avatarUrl;
  final Value<bool> isCat;
  final Value<bool> isAdmin;
  final Value<DateTime> addedAt;
  final Value<DateTime?> lastUsedAt;
  final Value<int> rowid;
  const AccountsCompanion({
    this.id = const Value.absent(),
    this.host = const Value.absent(),
    this.userId = const Value.absent(),
    this.username = const Value.absent(),
    this.displayName = const Value.absent(),
    this.avatarUrl = const Value.absent(),
    this.isCat = const Value.absent(),
    this.isAdmin = const Value.absent(),
    this.addedAt = const Value.absent(),
    this.lastUsedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AccountsCompanion.insert({
    required String id,
    required String host,
    required String userId,
    required String username,
    this.displayName = const Value.absent(),
    this.avatarUrl = const Value.absent(),
    this.isCat = const Value.absent(),
    this.isAdmin = const Value.absent(),
    required DateTime addedAt,
    this.lastUsedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       host = Value(host),
       userId = Value(userId),
       username = Value(username),
       addedAt = Value(addedAt);
  static Insertable<AccountRow> custom({
    Expression<String>? id,
    Expression<String>? host,
    Expression<String>? userId,
    Expression<String>? username,
    Expression<String>? displayName,
    Expression<String>? avatarUrl,
    Expression<bool>? isCat,
    Expression<bool>? isAdmin,
    Expression<DateTime>? addedAt,
    Expression<DateTime>? lastUsedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (host != null) 'host': host,
      if (userId != null) 'user_id': userId,
      if (username != null) 'username': username,
      if (displayName != null) 'display_name': displayName,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (isCat != null) 'is_cat': isCat,
      if (isAdmin != null) 'is_admin': isAdmin,
      if (addedAt != null) 'added_at': addedAt,
      if (lastUsedAt != null) 'last_used_at': lastUsedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AccountsCompanion copyWith({
    Value<String>? id,
    Value<String>? host,
    Value<String>? userId,
    Value<String>? username,
    Value<String?>? displayName,
    Value<String?>? avatarUrl,
    Value<bool>? isCat,
    Value<bool>? isAdmin,
    Value<DateTime>? addedAt,
    Value<DateTime?>? lastUsedAt,
    Value<int>? rowid,
  }) {
    return AccountsCompanion(
      id: id ?? this.id,
      host: host ?? this.host,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isCat: isCat ?? this.isCat,
      isAdmin: isAdmin ?? this.isAdmin,
      addedAt: addedAt ?? this.addedAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (host.present) {
      map['host'] = Variable<String>(host.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (username.present) {
      map['username'] = Variable<String>(username.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (avatarUrl.present) {
      map['avatar_url'] = Variable<String>(avatarUrl.value);
    }
    if (isCat.present) {
      map['is_cat'] = Variable<bool>(isCat.value);
    }
    if (isAdmin.present) {
      map['is_admin'] = Variable<bool>(isAdmin.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<DateTime>(addedAt.value);
    }
    if (lastUsedAt.present) {
      map['last_used_at'] = Variable<DateTime>(lastUsedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AccountsCompanion(')
          ..write('id: $id, ')
          ..write('host: $host, ')
          ..write('userId: $userId, ')
          ..write('username: $username, ')
          ..write('displayName: $displayName, ')
          ..write('avatarUrl: $avatarUrl, ')
          ..write('isCat: $isCat, ')
          ..write('isAdmin: $isAdmin, ')
          ..write('addedAt: $addedAt, ')
          ..write('lastUsedAt: $lastUsedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UsersTable extends Users with TableInfo<$UsersTable, UserRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UsersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _viewerHostMeta = const VerificationMeta(
    'viewerHost',
  );
  @override
  late final GeneratedColumn<String> viewerHost = GeneratedColumn<String>(
    'viewer_host',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _usernameMeta = const VerificationMeta(
    'username',
  );
  @override
  late final GeneratedColumn<String> username = GeneratedColumn<String>(
    'username',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hostMeta = const VerificationMeta('host');
  @override
  late final GeneratedColumn<String> host = GeneratedColumn<String>(
    'host',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _avatarUrlMeta = const VerificationMeta(
    'avatarUrl',
  );
  @override
  late final GeneratedColumn<String> avatarUrl = GeneratedColumn<String>(
    'avatar_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _avatarBlurhashMeta = const VerificationMeta(
    'avatarBlurhash',
  );
  @override
  late final GeneratedColumn<String> avatarBlurhash = GeneratedColumn<String>(
    'avatar_blurhash',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isBotMeta = const VerificationMeta('isBot');
  @override
  late final GeneratedColumn<bool> isBot = GeneratedColumn<bool>(
    'is_bot',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_bot" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isCatMeta = const VerificationMeta('isCat');
  @override
  late final GeneratedColumn<bool> isCat = GeneratedColumn<bool>(
    'is_cat',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_cat" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _fetchedAtMeta = const VerificationMeta(
    'fetchedAt',
  );
  @override
  late final GeneratedColumn<DateTime> fetchedAt = GeneratedColumn<DateTime>(
    'fetched_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rawJsonMeta = const VerificationMeta(
    'rawJson',
  );
  @override
  late final GeneratedColumn<String> rawJson = GeneratedColumn<String>(
    'raw_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    viewerHost,
    id,
    username,
    host,
    name,
    avatarUrl,
    avatarBlurhash,
    isBot,
    isCat,
    fetchedAt,
    rawJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'users';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('viewer_host')) {
      context.handle(
        _viewerHostMeta,
        viewerHost.isAcceptableOrUnknown(data['viewer_host']!, _viewerHostMeta),
      );
    } else if (isInserting) {
      context.missing(_viewerHostMeta);
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('username')) {
      context.handle(
        _usernameMeta,
        username.isAcceptableOrUnknown(data['username']!, _usernameMeta),
      );
    } else if (isInserting) {
      context.missing(_usernameMeta);
    }
    if (data.containsKey('host')) {
      context.handle(
        _hostMeta,
        host.isAcceptableOrUnknown(data['host']!, _hostMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('avatar_url')) {
      context.handle(
        _avatarUrlMeta,
        avatarUrl.isAcceptableOrUnknown(data['avatar_url']!, _avatarUrlMeta),
      );
    }
    if (data.containsKey('avatar_blurhash')) {
      context.handle(
        _avatarBlurhashMeta,
        avatarBlurhash.isAcceptableOrUnknown(
          data['avatar_blurhash']!,
          _avatarBlurhashMeta,
        ),
      );
    }
    if (data.containsKey('is_bot')) {
      context.handle(
        _isBotMeta,
        isBot.isAcceptableOrUnknown(data['is_bot']!, _isBotMeta),
      );
    }
    if (data.containsKey('is_cat')) {
      context.handle(
        _isCatMeta,
        isCat.isAcceptableOrUnknown(data['is_cat']!, _isCatMeta),
      );
    }
    if (data.containsKey('fetched_at')) {
      context.handle(
        _fetchedAtMeta,
        fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_fetchedAtMeta);
    }
    if (data.containsKey('raw_json')) {
      context.handle(
        _rawJsonMeta,
        rawJson.isAcceptableOrUnknown(data['raw_json']!, _rawJsonMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {viewerHost, id};
  @override
  UserRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserRow(
      viewerHost:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}viewer_host'],
          )!,
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}id'],
          )!,
      username:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}username'],
          )!,
      host: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}host'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      ),
      avatarUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}avatar_url'],
      ),
      avatarBlurhash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}avatar_blurhash'],
      ),
      isBot:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}is_bot'],
          )!,
      isCat:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}is_cat'],
          )!,
      fetchedAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}fetched_at'],
          )!,
      rawJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}raw_json'],
      ),
    );
  }

  @override
  $UsersTable createAlias(String alias) {
    return $UsersTable(attachedDatabase, alias);
  }
}

class UserRow extends DataClass implements Insertable<UserRow> {
  /// Observing host (which server's perspective stored this row).
  final String viewerHost;

  /// User id from `viewerHost`'s perspective.
  final String id;
  final String username;

  /// User's home host (null = local to viewerHost).
  final String? host;
  final String? name;
  final String? avatarUrl;
  final String? avatarBlurhash;
  final bool isBot;
  final bool isCat;
  final DateTime fetchedAt;
  final String? rawJson;
  const UserRow({
    required this.viewerHost,
    required this.id,
    required this.username,
    this.host,
    this.name,
    this.avatarUrl,
    this.avatarBlurhash,
    required this.isBot,
    required this.isCat,
    required this.fetchedAt,
    this.rawJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['viewer_host'] = Variable<String>(viewerHost);
    map['id'] = Variable<String>(id);
    map['username'] = Variable<String>(username);
    if (!nullToAbsent || host != null) {
      map['host'] = Variable<String>(host);
    }
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    if (!nullToAbsent || avatarUrl != null) {
      map['avatar_url'] = Variable<String>(avatarUrl);
    }
    if (!nullToAbsent || avatarBlurhash != null) {
      map['avatar_blurhash'] = Variable<String>(avatarBlurhash);
    }
    map['is_bot'] = Variable<bool>(isBot);
    map['is_cat'] = Variable<bool>(isCat);
    map['fetched_at'] = Variable<DateTime>(fetchedAt);
    if (!nullToAbsent || rawJson != null) {
      map['raw_json'] = Variable<String>(rawJson);
    }
    return map;
  }

  UsersCompanion toCompanion(bool nullToAbsent) {
    return UsersCompanion(
      viewerHost: Value(viewerHost),
      id: Value(id),
      username: Value(username),
      host: host == null && nullToAbsent ? const Value.absent() : Value(host),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      avatarUrl:
          avatarUrl == null && nullToAbsent
              ? const Value.absent()
              : Value(avatarUrl),
      avatarBlurhash:
          avatarBlurhash == null && nullToAbsent
              ? const Value.absent()
              : Value(avatarBlurhash),
      isBot: Value(isBot),
      isCat: Value(isCat),
      fetchedAt: Value(fetchedAt),
      rawJson:
          rawJson == null && nullToAbsent
              ? const Value.absent()
              : Value(rawJson),
    );
  }

  factory UserRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserRow(
      viewerHost: serializer.fromJson<String>(json['viewerHost']),
      id: serializer.fromJson<String>(json['id']),
      username: serializer.fromJson<String>(json['username']),
      host: serializer.fromJson<String?>(json['host']),
      name: serializer.fromJson<String?>(json['name']),
      avatarUrl: serializer.fromJson<String?>(json['avatarUrl']),
      avatarBlurhash: serializer.fromJson<String?>(json['avatarBlurhash']),
      isBot: serializer.fromJson<bool>(json['isBot']),
      isCat: serializer.fromJson<bool>(json['isCat']),
      fetchedAt: serializer.fromJson<DateTime>(json['fetchedAt']),
      rawJson: serializer.fromJson<String?>(json['rawJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'viewerHost': serializer.toJson<String>(viewerHost),
      'id': serializer.toJson<String>(id),
      'username': serializer.toJson<String>(username),
      'host': serializer.toJson<String?>(host),
      'name': serializer.toJson<String?>(name),
      'avatarUrl': serializer.toJson<String?>(avatarUrl),
      'avatarBlurhash': serializer.toJson<String?>(avatarBlurhash),
      'isBot': serializer.toJson<bool>(isBot),
      'isCat': serializer.toJson<bool>(isCat),
      'fetchedAt': serializer.toJson<DateTime>(fetchedAt),
      'rawJson': serializer.toJson<String?>(rawJson),
    };
  }

  UserRow copyWith({
    String? viewerHost,
    String? id,
    String? username,
    Value<String?> host = const Value.absent(),
    Value<String?> name = const Value.absent(),
    Value<String?> avatarUrl = const Value.absent(),
    Value<String?> avatarBlurhash = const Value.absent(),
    bool? isBot,
    bool? isCat,
    DateTime? fetchedAt,
    Value<String?> rawJson = const Value.absent(),
  }) => UserRow(
    viewerHost: viewerHost ?? this.viewerHost,
    id: id ?? this.id,
    username: username ?? this.username,
    host: host.present ? host.value : this.host,
    name: name.present ? name.value : this.name,
    avatarUrl: avatarUrl.present ? avatarUrl.value : this.avatarUrl,
    avatarBlurhash:
        avatarBlurhash.present ? avatarBlurhash.value : this.avatarBlurhash,
    isBot: isBot ?? this.isBot,
    isCat: isCat ?? this.isCat,
    fetchedAt: fetchedAt ?? this.fetchedAt,
    rawJson: rawJson.present ? rawJson.value : this.rawJson,
  );
  UserRow copyWithCompanion(UsersCompanion data) {
    return UserRow(
      viewerHost:
          data.viewerHost.present ? data.viewerHost.value : this.viewerHost,
      id: data.id.present ? data.id.value : this.id,
      username: data.username.present ? data.username.value : this.username,
      host: data.host.present ? data.host.value : this.host,
      name: data.name.present ? data.name.value : this.name,
      avatarUrl: data.avatarUrl.present ? data.avatarUrl.value : this.avatarUrl,
      avatarBlurhash:
          data.avatarBlurhash.present
              ? data.avatarBlurhash.value
              : this.avatarBlurhash,
      isBot: data.isBot.present ? data.isBot.value : this.isBot,
      isCat: data.isCat.present ? data.isCat.value : this.isCat,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
      rawJson: data.rawJson.present ? data.rawJson.value : this.rawJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserRow(')
          ..write('viewerHost: $viewerHost, ')
          ..write('id: $id, ')
          ..write('username: $username, ')
          ..write('host: $host, ')
          ..write('name: $name, ')
          ..write('avatarUrl: $avatarUrl, ')
          ..write('avatarBlurhash: $avatarBlurhash, ')
          ..write('isBot: $isBot, ')
          ..write('isCat: $isCat, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('rawJson: $rawJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    viewerHost,
    id,
    username,
    host,
    name,
    avatarUrl,
    avatarBlurhash,
    isBot,
    isCat,
    fetchedAt,
    rawJson,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserRow &&
          other.viewerHost == this.viewerHost &&
          other.id == this.id &&
          other.username == this.username &&
          other.host == this.host &&
          other.name == this.name &&
          other.avatarUrl == this.avatarUrl &&
          other.avatarBlurhash == this.avatarBlurhash &&
          other.isBot == this.isBot &&
          other.isCat == this.isCat &&
          other.fetchedAt == this.fetchedAt &&
          other.rawJson == this.rawJson);
}

class UsersCompanion extends UpdateCompanion<UserRow> {
  final Value<String> viewerHost;
  final Value<String> id;
  final Value<String> username;
  final Value<String?> host;
  final Value<String?> name;
  final Value<String?> avatarUrl;
  final Value<String?> avatarBlurhash;
  final Value<bool> isBot;
  final Value<bool> isCat;
  final Value<DateTime> fetchedAt;
  final Value<String?> rawJson;
  final Value<int> rowid;
  const UsersCompanion({
    this.viewerHost = const Value.absent(),
    this.id = const Value.absent(),
    this.username = const Value.absent(),
    this.host = const Value.absent(),
    this.name = const Value.absent(),
    this.avatarUrl = const Value.absent(),
    this.avatarBlurhash = const Value.absent(),
    this.isBot = const Value.absent(),
    this.isCat = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.rawJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UsersCompanion.insert({
    required String viewerHost,
    required String id,
    required String username,
    this.host = const Value.absent(),
    this.name = const Value.absent(),
    this.avatarUrl = const Value.absent(),
    this.avatarBlurhash = const Value.absent(),
    this.isBot = const Value.absent(),
    this.isCat = const Value.absent(),
    required DateTime fetchedAt,
    this.rawJson = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : viewerHost = Value(viewerHost),
       id = Value(id),
       username = Value(username),
       fetchedAt = Value(fetchedAt);
  static Insertable<UserRow> custom({
    Expression<String>? viewerHost,
    Expression<String>? id,
    Expression<String>? username,
    Expression<String>? host,
    Expression<String>? name,
    Expression<String>? avatarUrl,
    Expression<String>? avatarBlurhash,
    Expression<bool>? isBot,
    Expression<bool>? isCat,
    Expression<DateTime>? fetchedAt,
    Expression<String>? rawJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (viewerHost != null) 'viewer_host': viewerHost,
      if (id != null) 'id': id,
      if (username != null) 'username': username,
      if (host != null) 'host': host,
      if (name != null) 'name': name,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (avatarBlurhash != null) 'avatar_blurhash': avatarBlurhash,
      if (isBot != null) 'is_bot': isBot,
      if (isCat != null) 'is_cat': isCat,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (rawJson != null) 'raw_json': rawJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UsersCompanion copyWith({
    Value<String>? viewerHost,
    Value<String>? id,
    Value<String>? username,
    Value<String?>? host,
    Value<String?>? name,
    Value<String?>? avatarUrl,
    Value<String?>? avatarBlurhash,
    Value<bool>? isBot,
    Value<bool>? isCat,
    Value<DateTime>? fetchedAt,
    Value<String?>? rawJson,
    Value<int>? rowid,
  }) {
    return UsersCompanion(
      viewerHost: viewerHost ?? this.viewerHost,
      id: id ?? this.id,
      username: username ?? this.username,
      host: host ?? this.host,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      avatarBlurhash: avatarBlurhash ?? this.avatarBlurhash,
      isBot: isBot ?? this.isBot,
      isCat: isCat ?? this.isCat,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      rawJson: rawJson ?? this.rawJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (viewerHost.present) {
      map['viewer_host'] = Variable<String>(viewerHost.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (username.present) {
      map['username'] = Variable<String>(username.value);
    }
    if (host.present) {
      map['host'] = Variable<String>(host.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (avatarUrl.present) {
      map['avatar_url'] = Variable<String>(avatarUrl.value);
    }
    if (avatarBlurhash.present) {
      map['avatar_blurhash'] = Variable<String>(avatarBlurhash.value);
    }
    if (isBot.present) {
      map['is_bot'] = Variable<bool>(isBot.value);
    }
    if (isCat.present) {
      map['is_cat'] = Variable<bool>(isCat.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<DateTime>(fetchedAt.value);
    }
    if (rawJson.present) {
      map['raw_json'] = Variable<String>(rawJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UsersCompanion(')
          ..write('viewerHost: $viewerHost, ')
          ..write('id: $id, ')
          ..write('username: $username, ')
          ..write('host: $host, ')
          ..write('name: $name, ')
          ..write('avatarUrl: $avatarUrl, ')
          ..write('avatarBlurhash: $avatarBlurhash, ')
          ..write('isBot: $isBot, ')
          ..write('isCat: $isCat, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('rawJson: $rawJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $NotesTable extends Notes with TableInfo<$NotesTable, NoteRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NotesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _sourceHostMeta = const VerificationMeta(
    'sourceHost',
  );
  @override
  late final GeneratedColumn<String> sourceHost = GeneratedColumn<String>(
    'source_host',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userViewerHostMeta = const VerificationMeta(
    'userViewerHost',
  );
  @override
  late final GeneratedColumn<String> userViewerHost = GeneratedColumn<String>(
    'user_viewer_host',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cwMeta = const VerificationMeta('cw');
  @override
  late final GeneratedColumn<String> cw = GeneratedColumn<String>(
    'cw',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _visibilityMeta = const VerificationMeta(
    'visibility',
  );
  @override
  late final GeneratedColumn<String> visibility = GeneratedColumn<String>(
    'visibility',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _replyIdMeta = const VerificationMeta(
    'replyId',
  );
  @override
  late final GeneratedColumn<String> replyId = GeneratedColumn<String>(
    'reply_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _renoteIdMeta = const VerificationMeta(
    'renoteId',
  );
  @override
  late final GeneratedColumn<String> renoteId = GeneratedColumn<String>(
    'renote_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _repliesCountMeta = const VerificationMeta(
    'repliesCount',
  );
  @override
  late final GeneratedColumn<int> repliesCount = GeneratedColumn<int>(
    'replies_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _renoteCountMeta = const VerificationMeta(
    'renoteCount',
  );
  @override
  late final GeneratedColumn<int> renoteCount = GeneratedColumn<int>(
    'renote_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _reactionsJsonMeta = const VerificationMeta(
    'reactionsJson',
  );
  @override
  late final GeneratedColumn<String> reactionsJson = GeneratedColumn<String>(
    'reactions_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rawJsonMeta = const VerificationMeta(
    'rawJson',
  );
  @override
  late final GeneratedColumn<String> rawJson = GeneratedColumn<String>(
    'raw_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _revisionMeta = const VerificationMeta(
    'revision',
  );
  @override
  late final GeneratedColumn<int> revision = GeneratedColumn<int>(
    'revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    sourceHost,
    id,
    userViewerHost,
    userId,
    createdAt,
    updatedAt,
    body,
    cw,
    visibility,
    replyId,
    renoteId,
    repliesCount,
    renoteCount,
    reactionsJson,
    rawJson,
    revision,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'notes';
  @override
  VerificationContext validateIntegrity(
    Insertable<NoteRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('source_host')) {
      context.handle(
        _sourceHostMeta,
        sourceHost.isAcceptableOrUnknown(data['source_host']!, _sourceHostMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceHostMeta);
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_viewer_host')) {
      context.handle(
        _userViewerHostMeta,
        userViewerHost.isAcceptableOrUnknown(
          data['user_viewer_host']!,
          _userViewerHostMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_userViewerHostMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('text')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['text']!, _bodyMeta),
      );
    }
    if (data.containsKey('cw')) {
      context.handle(_cwMeta, cw.isAcceptableOrUnknown(data['cw']!, _cwMeta));
    }
    if (data.containsKey('visibility')) {
      context.handle(
        _visibilityMeta,
        visibility.isAcceptableOrUnknown(data['visibility']!, _visibilityMeta),
      );
    } else if (isInserting) {
      context.missing(_visibilityMeta);
    }
    if (data.containsKey('reply_id')) {
      context.handle(
        _replyIdMeta,
        replyId.isAcceptableOrUnknown(data['reply_id']!, _replyIdMeta),
      );
    }
    if (data.containsKey('renote_id')) {
      context.handle(
        _renoteIdMeta,
        renoteId.isAcceptableOrUnknown(data['renote_id']!, _renoteIdMeta),
      );
    }
    if (data.containsKey('replies_count')) {
      context.handle(
        _repliesCountMeta,
        repliesCount.isAcceptableOrUnknown(
          data['replies_count']!,
          _repliesCountMeta,
        ),
      );
    }
    if (data.containsKey('renote_count')) {
      context.handle(
        _renoteCountMeta,
        renoteCount.isAcceptableOrUnknown(
          data['renote_count']!,
          _renoteCountMeta,
        ),
      );
    }
    if (data.containsKey('reactions_json')) {
      context.handle(
        _reactionsJsonMeta,
        reactionsJson.isAcceptableOrUnknown(
          data['reactions_json']!,
          _reactionsJsonMeta,
        ),
      );
    }
    if (data.containsKey('raw_json')) {
      context.handle(
        _rawJsonMeta,
        rawJson.isAcceptableOrUnknown(data['raw_json']!, _rawJsonMeta),
      );
    }
    if (data.containsKey('revision')) {
      context.handle(
        _revisionMeta,
        revision.isAcceptableOrUnknown(data['revision']!, _revisionMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {sourceHost, id};
  @override
  NoteRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NoteRow(
      sourceHost:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}source_host'],
          )!,
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}id'],
          )!,
      userViewerHost:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}user_viewer_host'],
          )!,
      userId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}user_id'],
          )!,
      createdAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}created_at'],
          )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      ),
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}text'],
      ),
      cw: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cw'],
      ),
      visibility:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}visibility'],
          )!,
      replyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reply_id'],
      ),
      renoteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}renote_id'],
      ),
      repliesCount:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}replies_count'],
          )!,
      renoteCount:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}renote_count'],
          )!,
      reactionsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reactions_json'],
      ),
      rawJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}raw_json'],
      ),
      revision:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}revision'],
          )!,
    );
  }

  @override
  $NotesTable createAlias(String alias) {
    return $NotesTable(attachedDatabase, alias);
  }
}

class NoteRow extends DataClass implements Insertable<NoteRow> {
  final String sourceHost;
  final String id;
  final String userViewerHost;
  final String userId;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? body;
  final String? cw;
  final String visibility;
  final String? replyId;
  final String? renoteId;
  final int repliesCount;
  final int renoteCount;

  /// JSON-encoded reactions list. Counts churn fast; storing structured
  /// rows is more write traffic than this is worth at MVP.
  final String? reactionsJson;

  /// Full original JSON for forward-compat.
  final String? rawJson;

  /// Monotonic revision: bumped on edit/reaction/replyCount change so
  /// the height cache (M6) can key on it.
  final int revision;
  const NoteRow({
    required this.sourceHost,
    required this.id,
    required this.userViewerHost,
    required this.userId,
    required this.createdAt,
    this.updatedAt,
    this.body,
    this.cw,
    required this.visibility,
    this.replyId,
    this.renoteId,
    required this.repliesCount,
    required this.renoteCount,
    this.reactionsJson,
    this.rawJson,
    required this.revision,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['source_host'] = Variable<String>(sourceHost);
    map['id'] = Variable<String>(id);
    map['user_viewer_host'] = Variable<String>(userViewerHost);
    map['user_id'] = Variable<String>(userId);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    if (!nullToAbsent || body != null) {
      map['text'] = Variable<String>(body);
    }
    if (!nullToAbsent || cw != null) {
      map['cw'] = Variable<String>(cw);
    }
    map['visibility'] = Variable<String>(visibility);
    if (!nullToAbsent || replyId != null) {
      map['reply_id'] = Variable<String>(replyId);
    }
    if (!nullToAbsent || renoteId != null) {
      map['renote_id'] = Variable<String>(renoteId);
    }
    map['replies_count'] = Variable<int>(repliesCount);
    map['renote_count'] = Variable<int>(renoteCount);
    if (!nullToAbsent || reactionsJson != null) {
      map['reactions_json'] = Variable<String>(reactionsJson);
    }
    if (!nullToAbsent || rawJson != null) {
      map['raw_json'] = Variable<String>(rawJson);
    }
    map['revision'] = Variable<int>(revision);
    return map;
  }

  NotesCompanion toCompanion(bool nullToAbsent) {
    return NotesCompanion(
      sourceHost: Value(sourceHost),
      id: Value(id),
      userViewerHost: Value(userViewerHost),
      userId: Value(userId),
      createdAt: Value(createdAt),
      updatedAt:
          updatedAt == null && nullToAbsent
              ? const Value.absent()
              : Value(updatedAt),
      body: body == null && nullToAbsent ? const Value.absent() : Value(body),
      cw: cw == null && nullToAbsent ? const Value.absent() : Value(cw),
      visibility: Value(visibility),
      replyId:
          replyId == null && nullToAbsent
              ? const Value.absent()
              : Value(replyId),
      renoteId:
          renoteId == null && nullToAbsent
              ? const Value.absent()
              : Value(renoteId),
      repliesCount: Value(repliesCount),
      renoteCount: Value(renoteCount),
      reactionsJson:
          reactionsJson == null && nullToAbsent
              ? const Value.absent()
              : Value(reactionsJson),
      rawJson:
          rawJson == null && nullToAbsent
              ? const Value.absent()
              : Value(rawJson),
      revision: Value(revision),
    );
  }

  factory NoteRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NoteRow(
      sourceHost: serializer.fromJson<String>(json['sourceHost']),
      id: serializer.fromJson<String>(json['id']),
      userViewerHost: serializer.fromJson<String>(json['userViewerHost']),
      userId: serializer.fromJson<String>(json['userId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
      body: serializer.fromJson<String?>(json['body']),
      cw: serializer.fromJson<String?>(json['cw']),
      visibility: serializer.fromJson<String>(json['visibility']),
      replyId: serializer.fromJson<String?>(json['replyId']),
      renoteId: serializer.fromJson<String?>(json['renoteId']),
      repliesCount: serializer.fromJson<int>(json['repliesCount']),
      renoteCount: serializer.fromJson<int>(json['renoteCount']),
      reactionsJson: serializer.fromJson<String?>(json['reactionsJson']),
      rawJson: serializer.fromJson<String?>(json['rawJson']),
      revision: serializer.fromJson<int>(json['revision']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'sourceHost': serializer.toJson<String>(sourceHost),
      'id': serializer.toJson<String>(id),
      'userViewerHost': serializer.toJson<String>(userViewerHost),
      'userId': serializer.toJson<String>(userId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
      'body': serializer.toJson<String?>(body),
      'cw': serializer.toJson<String?>(cw),
      'visibility': serializer.toJson<String>(visibility),
      'replyId': serializer.toJson<String?>(replyId),
      'renoteId': serializer.toJson<String?>(renoteId),
      'repliesCount': serializer.toJson<int>(repliesCount),
      'renoteCount': serializer.toJson<int>(renoteCount),
      'reactionsJson': serializer.toJson<String?>(reactionsJson),
      'rawJson': serializer.toJson<String?>(rawJson),
      'revision': serializer.toJson<int>(revision),
    };
  }

  NoteRow copyWith({
    String? sourceHost,
    String? id,
    String? userViewerHost,
    String? userId,
    DateTime? createdAt,
    Value<DateTime?> updatedAt = const Value.absent(),
    Value<String?> body = const Value.absent(),
    Value<String?> cw = const Value.absent(),
    String? visibility,
    Value<String?> replyId = const Value.absent(),
    Value<String?> renoteId = const Value.absent(),
    int? repliesCount,
    int? renoteCount,
    Value<String?> reactionsJson = const Value.absent(),
    Value<String?> rawJson = const Value.absent(),
    int? revision,
  }) => NoteRow(
    sourceHost: sourceHost ?? this.sourceHost,
    id: id ?? this.id,
    userViewerHost: userViewerHost ?? this.userViewerHost,
    userId: userId ?? this.userId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
    body: body.present ? body.value : this.body,
    cw: cw.present ? cw.value : this.cw,
    visibility: visibility ?? this.visibility,
    replyId: replyId.present ? replyId.value : this.replyId,
    renoteId: renoteId.present ? renoteId.value : this.renoteId,
    repliesCount: repliesCount ?? this.repliesCount,
    renoteCount: renoteCount ?? this.renoteCount,
    reactionsJson:
        reactionsJson.present ? reactionsJson.value : this.reactionsJson,
    rawJson: rawJson.present ? rawJson.value : this.rawJson,
    revision: revision ?? this.revision,
  );
  NoteRow copyWithCompanion(NotesCompanion data) {
    return NoteRow(
      sourceHost:
          data.sourceHost.present ? data.sourceHost.value : this.sourceHost,
      id: data.id.present ? data.id.value : this.id,
      userViewerHost:
          data.userViewerHost.present
              ? data.userViewerHost.value
              : this.userViewerHost,
      userId: data.userId.present ? data.userId.value : this.userId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      body: data.body.present ? data.body.value : this.body,
      cw: data.cw.present ? data.cw.value : this.cw,
      visibility:
          data.visibility.present ? data.visibility.value : this.visibility,
      replyId: data.replyId.present ? data.replyId.value : this.replyId,
      renoteId: data.renoteId.present ? data.renoteId.value : this.renoteId,
      repliesCount:
          data.repliesCount.present
              ? data.repliesCount.value
              : this.repliesCount,
      renoteCount:
          data.renoteCount.present ? data.renoteCount.value : this.renoteCount,
      reactionsJson:
          data.reactionsJson.present
              ? data.reactionsJson.value
              : this.reactionsJson,
      rawJson: data.rawJson.present ? data.rawJson.value : this.rawJson,
      revision: data.revision.present ? data.revision.value : this.revision,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NoteRow(')
          ..write('sourceHost: $sourceHost, ')
          ..write('id: $id, ')
          ..write('userViewerHost: $userViewerHost, ')
          ..write('userId: $userId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('body: $body, ')
          ..write('cw: $cw, ')
          ..write('visibility: $visibility, ')
          ..write('replyId: $replyId, ')
          ..write('renoteId: $renoteId, ')
          ..write('repliesCount: $repliesCount, ')
          ..write('renoteCount: $renoteCount, ')
          ..write('reactionsJson: $reactionsJson, ')
          ..write('rawJson: $rawJson, ')
          ..write('revision: $revision')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    sourceHost,
    id,
    userViewerHost,
    userId,
    createdAt,
    updatedAt,
    body,
    cw,
    visibility,
    replyId,
    renoteId,
    repliesCount,
    renoteCount,
    reactionsJson,
    rawJson,
    revision,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NoteRow &&
          other.sourceHost == this.sourceHost &&
          other.id == this.id &&
          other.userViewerHost == this.userViewerHost &&
          other.userId == this.userId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.body == this.body &&
          other.cw == this.cw &&
          other.visibility == this.visibility &&
          other.replyId == this.replyId &&
          other.renoteId == this.renoteId &&
          other.repliesCount == this.repliesCount &&
          other.renoteCount == this.renoteCount &&
          other.reactionsJson == this.reactionsJson &&
          other.rawJson == this.rawJson &&
          other.revision == this.revision);
}

class NotesCompanion extends UpdateCompanion<NoteRow> {
  final Value<String> sourceHost;
  final Value<String> id;
  final Value<String> userViewerHost;
  final Value<String> userId;
  final Value<DateTime> createdAt;
  final Value<DateTime?> updatedAt;
  final Value<String?> body;
  final Value<String?> cw;
  final Value<String> visibility;
  final Value<String?> replyId;
  final Value<String?> renoteId;
  final Value<int> repliesCount;
  final Value<int> renoteCount;
  final Value<String?> reactionsJson;
  final Value<String?> rawJson;
  final Value<int> revision;
  final Value<int> rowid;
  const NotesCompanion({
    this.sourceHost = const Value.absent(),
    this.id = const Value.absent(),
    this.userViewerHost = const Value.absent(),
    this.userId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.body = const Value.absent(),
    this.cw = const Value.absent(),
    this.visibility = const Value.absent(),
    this.replyId = const Value.absent(),
    this.renoteId = const Value.absent(),
    this.repliesCount = const Value.absent(),
    this.renoteCount = const Value.absent(),
    this.reactionsJson = const Value.absent(),
    this.rawJson = const Value.absent(),
    this.revision = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NotesCompanion.insert({
    required String sourceHost,
    required String id,
    required String userViewerHost,
    required String userId,
    required DateTime createdAt,
    this.updatedAt = const Value.absent(),
    this.body = const Value.absent(),
    this.cw = const Value.absent(),
    required String visibility,
    this.replyId = const Value.absent(),
    this.renoteId = const Value.absent(),
    this.repliesCount = const Value.absent(),
    this.renoteCount = const Value.absent(),
    this.reactionsJson = const Value.absent(),
    this.rawJson = const Value.absent(),
    this.revision = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : sourceHost = Value(sourceHost),
       id = Value(id),
       userViewerHost = Value(userViewerHost),
       userId = Value(userId),
       createdAt = Value(createdAt),
       visibility = Value(visibility);
  static Insertable<NoteRow> custom({
    Expression<String>? sourceHost,
    Expression<String>? id,
    Expression<String>? userViewerHost,
    Expression<String>? userId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? body,
    Expression<String>? cw,
    Expression<String>? visibility,
    Expression<String>? replyId,
    Expression<String>? renoteId,
    Expression<int>? repliesCount,
    Expression<int>? renoteCount,
    Expression<String>? reactionsJson,
    Expression<String>? rawJson,
    Expression<int>? revision,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (sourceHost != null) 'source_host': sourceHost,
      if (id != null) 'id': id,
      if (userViewerHost != null) 'user_viewer_host': userViewerHost,
      if (userId != null) 'user_id': userId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (body != null) 'text': body,
      if (cw != null) 'cw': cw,
      if (visibility != null) 'visibility': visibility,
      if (replyId != null) 'reply_id': replyId,
      if (renoteId != null) 'renote_id': renoteId,
      if (repliesCount != null) 'replies_count': repliesCount,
      if (renoteCount != null) 'renote_count': renoteCount,
      if (reactionsJson != null) 'reactions_json': reactionsJson,
      if (rawJson != null) 'raw_json': rawJson,
      if (revision != null) 'revision': revision,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NotesCompanion copyWith({
    Value<String>? sourceHost,
    Value<String>? id,
    Value<String>? userViewerHost,
    Value<String>? userId,
    Value<DateTime>? createdAt,
    Value<DateTime?>? updatedAt,
    Value<String?>? body,
    Value<String?>? cw,
    Value<String>? visibility,
    Value<String?>? replyId,
    Value<String?>? renoteId,
    Value<int>? repliesCount,
    Value<int>? renoteCount,
    Value<String?>? reactionsJson,
    Value<String?>? rawJson,
    Value<int>? revision,
    Value<int>? rowid,
  }) {
    return NotesCompanion(
      sourceHost: sourceHost ?? this.sourceHost,
      id: id ?? this.id,
      userViewerHost: userViewerHost ?? this.userViewerHost,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      body: body ?? this.body,
      cw: cw ?? this.cw,
      visibility: visibility ?? this.visibility,
      replyId: replyId ?? this.replyId,
      renoteId: renoteId ?? this.renoteId,
      repliesCount: repliesCount ?? this.repliesCount,
      renoteCount: renoteCount ?? this.renoteCount,
      reactionsJson: reactionsJson ?? this.reactionsJson,
      rawJson: rawJson ?? this.rawJson,
      revision: revision ?? this.revision,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (sourceHost.present) {
      map['source_host'] = Variable<String>(sourceHost.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userViewerHost.present) {
      map['user_viewer_host'] = Variable<String>(userViewerHost.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (body.present) {
      map['text'] = Variable<String>(body.value);
    }
    if (cw.present) {
      map['cw'] = Variable<String>(cw.value);
    }
    if (visibility.present) {
      map['visibility'] = Variable<String>(visibility.value);
    }
    if (replyId.present) {
      map['reply_id'] = Variable<String>(replyId.value);
    }
    if (renoteId.present) {
      map['renote_id'] = Variable<String>(renoteId.value);
    }
    if (repliesCount.present) {
      map['replies_count'] = Variable<int>(repliesCount.value);
    }
    if (renoteCount.present) {
      map['renote_count'] = Variable<int>(renoteCount.value);
    }
    if (reactionsJson.present) {
      map['reactions_json'] = Variable<String>(reactionsJson.value);
    }
    if (rawJson.present) {
      map['raw_json'] = Variable<String>(rawJson.value);
    }
    if (revision.present) {
      map['revision'] = Variable<int>(revision.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NotesCompanion(')
          ..write('sourceHost: $sourceHost, ')
          ..write('id: $id, ')
          ..write('userViewerHost: $userViewerHost, ')
          ..write('userId: $userId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('body: $body, ')
          ..write('cw: $cw, ')
          ..write('visibility: $visibility, ')
          ..write('replyId: $replyId, ')
          ..write('renoteId: $renoteId, ')
          ..write('repliesCount: $repliesCount, ')
          ..write('renoteCount: $renoteCount, ')
          ..write('reactionsJson: $reactionsJson, ')
          ..write('rawJson: $rawJson, ')
          ..write('revision: $revision, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EmojisTable extends Emojis with TableInfo<$EmojisTable, EmojiRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EmojisTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _hostMeta = const VerificationMeta('host');
  @override
  late final GeneratedColumn<String> host = GeneratedColumn<String>(
    'host',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
    'url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _aliasesJsonMeta = const VerificationMeta(
    'aliasesJson',
  );
  @override
  late final GeneratedColumn<String> aliasesJson = GeneratedColumn<String>(
    'aliases_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sensitiveMeta = const VerificationMeta(
    'sensitive',
  );
  @override
  late final GeneratedColumn<bool> sensitive = GeneratedColumn<bool>(
    'sensitive',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("sensitive" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _fetchedAtMeta = const VerificationMeta(
    'fetchedAt',
  );
  @override
  late final GeneratedColumn<DateTime> fetchedAt = GeneratedColumn<DateTime>(
    'fetched_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    host,
    name,
    url,
    aliasesJson,
    category,
    sensitive,
    fetchedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'emojis';
  @override
  VerificationContext validateIntegrity(
    Insertable<EmojiRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('host')) {
      context.handle(
        _hostMeta,
        host.isAcceptableOrUnknown(data['host']!, _hostMeta),
      );
    } else if (isInserting) {
      context.missing(_hostMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('url')) {
      context.handle(
        _urlMeta,
        url.isAcceptableOrUnknown(data['url']!, _urlMeta),
      );
    } else if (isInserting) {
      context.missing(_urlMeta);
    }
    if (data.containsKey('aliases_json')) {
      context.handle(
        _aliasesJsonMeta,
        aliasesJson.isAcceptableOrUnknown(
          data['aliases_json']!,
          _aliasesJsonMeta,
        ),
      );
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    }
    if (data.containsKey('sensitive')) {
      context.handle(
        _sensitiveMeta,
        sensitive.isAcceptableOrUnknown(data['sensitive']!, _sensitiveMeta),
      );
    }
    if (data.containsKey('fetched_at')) {
      context.handle(
        _fetchedAtMeta,
        fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_fetchedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {host, name};
  @override
  EmojiRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EmojiRow(
      host:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}host'],
          )!,
      name:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}name'],
          )!,
      url:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}url'],
          )!,
      aliasesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}aliases_json'],
      ),
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      ),
      sensitive:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}sensitive'],
          )!,
      fetchedAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}fetched_at'],
          )!,
    );
  }

  @override
  $EmojisTable createAlias(String alias) {
    return $EmojisTable(attachedDatabase, alias);
  }
}

class EmojiRow extends DataClass implements Insertable<EmojiRow> {
  final String host;
  final String name;
  final String url;

  /// JSON-encoded `List<String>` of aliases.
  final String? aliasesJson;
  final String? category;
  final bool sensitive;
  final DateTime fetchedAt;
  const EmojiRow({
    required this.host,
    required this.name,
    required this.url,
    this.aliasesJson,
    this.category,
    required this.sensitive,
    required this.fetchedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['host'] = Variable<String>(host);
    map['name'] = Variable<String>(name);
    map['url'] = Variable<String>(url);
    if (!nullToAbsent || aliasesJson != null) {
      map['aliases_json'] = Variable<String>(aliasesJson);
    }
    if (!nullToAbsent || category != null) {
      map['category'] = Variable<String>(category);
    }
    map['sensitive'] = Variable<bool>(sensitive);
    map['fetched_at'] = Variable<DateTime>(fetchedAt);
    return map;
  }

  EmojisCompanion toCompanion(bool nullToAbsent) {
    return EmojisCompanion(
      host: Value(host),
      name: Value(name),
      url: Value(url),
      aliasesJson:
          aliasesJson == null && nullToAbsent
              ? const Value.absent()
              : Value(aliasesJson),
      category:
          category == null && nullToAbsent
              ? const Value.absent()
              : Value(category),
      sensitive: Value(sensitive),
      fetchedAt: Value(fetchedAt),
    );
  }

  factory EmojiRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EmojiRow(
      host: serializer.fromJson<String>(json['host']),
      name: serializer.fromJson<String>(json['name']),
      url: serializer.fromJson<String>(json['url']),
      aliasesJson: serializer.fromJson<String?>(json['aliasesJson']),
      category: serializer.fromJson<String?>(json['category']),
      sensitive: serializer.fromJson<bool>(json['sensitive']),
      fetchedAt: serializer.fromJson<DateTime>(json['fetchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'host': serializer.toJson<String>(host),
      'name': serializer.toJson<String>(name),
      'url': serializer.toJson<String>(url),
      'aliasesJson': serializer.toJson<String?>(aliasesJson),
      'category': serializer.toJson<String?>(category),
      'sensitive': serializer.toJson<bool>(sensitive),
      'fetchedAt': serializer.toJson<DateTime>(fetchedAt),
    };
  }

  EmojiRow copyWith({
    String? host,
    String? name,
    String? url,
    Value<String?> aliasesJson = const Value.absent(),
    Value<String?> category = const Value.absent(),
    bool? sensitive,
    DateTime? fetchedAt,
  }) => EmojiRow(
    host: host ?? this.host,
    name: name ?? this.name,
    url: url ?? this.url,
    aliasesJson: aliasesJson.present ? aliasesJson.value : this.aliasesJson,
    category: category.present ? category.value : this.category,
    sensitive: sensitive ?? this.sensitive,
    fetchedAt: fetchedAt ?? this.fetchedAt,
  );
  EmojiRow copyWithCompanion(EmojisCompanion data) {
    return EmojiRow(
      host: data.host.present ? data.host.value : this.host,
      name: data.name.present ? data.name.value : this.name,
      url: data.url.present ? data.url.value : this.url,
      aliasesJson:
          data.aliasesJson.present ? data.aliasesJson.value : this.aliasesJson,
      category: data.category.present ? data.category.value : this.category,
      sensitive: data.sensitive.present ? data.sensitive.value : this.sensitive,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EmojiRow(')
          ..write('host: $host, ')
          ..write('name: $name, ')
          ..write('url: $url, ')
          ..write('aliasesJson: $aliasesJson, ')
          ..write('category: $category, ')
          ..write('sensitive: $sensitive, ')
          ..write('fetchedAt: $fetchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(host, name, url, aliasesJson, category, sensitive, fetchedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EmojiRow &&
          other.host == this.host &&
          other.name == this.name &&
          other.url == this.url &&
          other.aliasesJson == this.aliasesJson &&
          other.category == this.category &&
          other.sensitive == this.sensitive &&
          other.fetchedAt == this.fetchedAt);
}

class EmojisCompanion extends UpdateCompanion<EmojiRow> {
  final Value<String> host;
  final Value<String> name;
  final Value<String> url;
  final Value<String?> aliasesJson;
  final Value<String?> category;
  final Value<bool> sensitive;
  final Value<DateTime> fetchedAt;
  final Value<int> rowid;
  const EmojisCompanion({
    this.host = const Value.absent(),
    this.name = const Value.absent(),
    this.url = const Value.absent(),
    this.aliasesJson = const Value.absent(),
    this.category = const Value.absent(),
    this.sensitive = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EmojisCompanion.insert({
    required String host,
    required String name,
    required String url,
    this.aliasesJson = const Value.absent(),
    this.category = const Value.absent(),
    this.sensitive = const Value.absent(),
    required DateTime fetchedAt,
    this.rowid = const Value.absent(),
  }) : host = Value(host),
       name = Value(name),
       url = Value(url),
       fetchedAt = Value(fetchedAt);
  static Insertable<EmojiRow> custom({
    Expression<String>? host,
    Expression<String>? name,
    Expression<String>? url,
    Expression<String>? aliasesJson,
    Expression<String>? category,
    Expression<bool>? sensitive,
    Expression<DateTime>? fetchedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (host != null) 'host': host,
      if (name != null) 'name': name,
      if (url != null) 'url': url,
      if (aliasesJson != null) 'aliases_json': aliasesJson,
      if (category != null) 'category': category,
      if (sensitive != null) 'sensitive': sensitive,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EmojisCompanion copyWith({
    Value<String>? host,
    Value<String>? name,
    Value<String>? url,
    Value<String?>? aliasesJson,
    Value<String?>? category,
    Value<bool>? sensitive,
    Value<DateTime>? fetchedAt,
    Value<int>? rowid,
  }) {
    return EmojisCompanion(
      host: host ?? this.host,
      name: name ?? this.name,
      url: url ?? this.url,
      aliasesJson: aliasesJson ?? this.aliasesJson,
      category: category ?? this.category,
      sensitive: sensitive ?? this.sensitive,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (host.present) {
      map['host'] = Variable<String>(host.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (aliasesJson.present) {
      map['aliases_json'] = Variable<String>(aliasesJson.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (sensitive.present) {
      map['sensitive'] = Variable<bool>(sensitive.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<DateTime>(fetchedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EmojisCompanion(')
          ..write('host: $host, ')
          ..write('name: $name, ')
          ..write('url: $url, ')
          ..write('aliasesJson: $aliasesJson, ')
          ..write('category: $category, ')
          ..write('sensitive: $sensitive, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EmojiCatalogsTable extends EmojiCatalogs
    with TableInfo<$EmojiCatalogsTable, EmojiCatalogRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EmojiCatalogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _hostMeta = const VerificationMeta('host');
  @override
  late final GeneratedColumn<String> host = GeneratedColumn<String>(
    'host',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fetchedAtMeta = const VerificationMeta(
    'fetchedAt',
  );
  @override
  late final GeneratedColumn<DateTime> fetchedAt = GeneratedColumn<DateTime>(
    'fetched_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [host, fetchedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'emoji_catalogs';
  @override
  VerificationContext validateIntegrity(
    Insertable<EmojiCatalogRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('host')) {
      context.handle(
        _hostMeta,
        host.isAcceptableOrUnknown(data['host']!, _hostMeta),
      );
    } else if (isInserting) {
      context.missing(_hostMeta);
    }
    if (data.containsKey('fetched_at')) {
      context.handle(
        _fetchedAtMeta,
        fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_fetchedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {host};
  @override
  EmojiCatalogRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EmojiCatalogRow(
      host:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}host'],
          )!,
      fetchedAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}fetched_at'],
          )!,
    );
  }

  @override
  $EmojiCatalogsTable createAlias(String alias) {
    return $EmojiCatalogsTable(attachedDatabase, alias);
  }
}

class EmojiCatalogRow extends DataClass implements Insertable<EmojiCatalogRow> {
  final String host;
  final DateTime fetchedAt;
  const EmojiCatalogRow({required this.host, required this.fetchedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['host'] = Variable<String>(host);
    map['fetched_at'] = Variable<DateTime>(fetchedAt);
    return map;
  }

  EmojiCatalogsCompanion toCompanion(bool nullToAbsent) {
    return EmojiCatalogsCompanion(
      host: Value(host),
      fetchedAt: Value(fetchedAt),
    );
  }

  factory EmojiCatalogRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EmojiCatalogRow(
      host: serializer.fromJson<String>(json['host']),
      fetchedAt: serializer.fromJson<DateTime>(json['fetchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'host': serializer.toJson<String>(host),
      'fetchedAt': serializer.toJson<DateTime>(fetchedAt),
    };
  }

  EmojiCatalogRow copyWith({String? host, DateTime? fetchedAt}) =>
      EmojiCatalogRow(
        host: host ?? this.host,
        fetchedAt: fetchedAt ?? this.fetchedAt,
      );
  EmojiCatalogRow copyWithCompanion(EmojiCatalogsCompanion data) {
    return EmojiCatalogRow(
      host: data.host.present ? data.host.value : this.host,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EmojiCatalogRow(')
          ..write('host: $host, ')
          ..write('fetchedAt: $fetchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(host, fetchedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EmojiCatalogRow &&
          other.host == this.host &&
          other.fetchedAt == this.fetchedAt);
}

class EmojiCatalogsCompanion extends UpdateCompanion<EmojiCatalogRow> {
  final Value<String> host;
  final Value<DateTime> fetchedAt;
  final Value<int> rowid;
  const EmojiCatalogsCompanion({
    this.host = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EmojiCatalogsCompanion.insert({
    required String host,
    required DateTime fetchedAt,
    this.rowid = const Value.absent(),
  }) : host = Value(host),
       fetchedAt = Value(fetchedAt);
  static Insertable<EmojiCatalogRow> custom({
    Expression<String>? host,
    Expression<DateTime>? fetchedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (host != null) 'host': host,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EmojiCatalogsCompanion copyWith({
    Value<String>? host,
    Value<DateTime>? fetchedAt,
    Value<int>? rowid,
  }) {
    return EmojiCatalogsCompanion(
      host: host ?? this.host,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (host.present) {
      map['host'] = Variable<String>(host.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<DateTime>(fetchedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EmojiCatalogsCompanion(')
          ..write('host: $host, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TimelineItemsTable extends TimelineItems
    with TableInfo<$TimelineItemsTable, TimelineItemRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TimelineItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timelineKeyMeta = const VerificationMeta(
    'timelineKey',
  );
  @override
  late final GeneratedColumn<String> timelineKey = GeneratedColumn<String>(
    'timeline_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteSourceHostMeta = const VerificationMeta(
    'noteSourceHost',
  );
  @override
  late final GeneratedColumn<String> noteSourceHost = GeneratedColumn<String>(
    'note_source_host',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteIdMeta = const VerificationMeta('noteId');
  @override
  late final GeneratedColumn<String> noteId = GeneratedColumn<String>(
    'note_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _receivedAtMeta = const VerificationMeta(
    'receivedAt',
  );
  @override
  late final GeneratedColumn<DateTime> receivedAt = GeneratedColumn<DateTime>(
    'received_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    accountId,
    timelineKey,
    noteSourceHost,
    noteId,
    createdAt,
    receivedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'timeline_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<TimelineItemRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('timeline_key')) {
      context.handle(
        _timelineKeyMeta,
        timelineKey.isAcceptableOrUnknown(
          data['timeline_key']!,
          _timelineKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_timelineKeyMeta);
    }
    if (data.containsKey('note_source_host')) {
      context.handle(
        _noteSourceHostMeta,
        noteSourceHost.isAcceptableOrUnknown(
          data['note_source_host']!,
          _noteSourceHostMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_noteSourceHostMeta);
    }
    if (data.containsKey('note_id')) {
      context.handle(
        _noteIdMeta,
        noteId.isAcceptableOrUnknown(data['note_id']!, _noteIdMeta),
      );
    } else if (isInserting) {
      context.missing(_noteIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('received_at')) {
      context.handle(
        _receivedAtMeta,
        receivedAt.isAcceptableOrUnknown(data['received_at']!, _receivedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_receivedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {
    accountId,
    timelineKey,
    noteSourceHost,
    noteId,
  };
  @override
  TimelineItemRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TimelineItemRow(
      accountId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}account_id'],
          )!,
      timelineKey:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}timeline_key'],
          )!,
      noteSourceHost:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}note_source_host'],
          )!,
      noteId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}note_id'],
          )!,
      createdAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}created_at'],
          )!,
      receivedAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}received_at'],
          )!,
    );
  }

  @override
  $TimelineItemsTable createAlias(String alias) {
    return $TimelineItemsTable(attachedDatabase, alias);
  }
}

class TimelineItemRow extends DataClass implements Insertable<TimelineItemRow> {
  /// Owning account ("host:userId").
  final String accountId;

  /// Timeline this note appears in for `accountId`. Values:
  /// `home`, `local`, `hybrid`, `global`, `mentions`, `notifications`,
  /// or per-list keys later.
  final String timelineKey;
  final String noteSourceHost;
  final String noteId;
  final DateTime createdAt;
  final DateTime receivedAt;
  const TimelineItemRow({
    required this.accountId,
    required this.timelineKey,
    required this.noteSourceHost,
    required this.noteId,
    required this.createdAt,
    required this.receivedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['account_id'] = Variable<String>(accountId);
    map['timeline_key'] = Variable<String>(timelineKey);
    map['note_source_host'] = Variable<String>(noteSourceHost);
    map['note_id'] = Variable<String>(noteId);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['received_at'] = Variable<DateTime>(receivedAt);
    return map;
  }

  TimelineItemsCompanion toCompanion(bool nullToAbsent) {
    return TimelineItemsCompanion(
      accountId: Value(accountId),
      timelineKey: Value(timelineKey),
      noteSourceHost: Value(noteSourceHost),
      noteId: Value(noteId),
      createdAt: Value(createdAt),
      receivedAt: Value(receivedAt),
    );
  }

  factory TimelineItemRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TimelineItemRow(
      accountId: serializer.fromJson<String>(json['accountId']),
      timelineKey: serializer.fromJson<String>(json['timelineKey']),
      noteSourceHost: serializer.fromJson<String>(json['noteSourceHost']),
      noteId: serializer.fromJson<String>(json['noteId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      receivedAt: serializer.fromJson<DateTime>(json['receivedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'accountId': serializer.toJson<String>(accountId),
      'timelineKey': serializer.toJson<String>(timelineKey),
      'noteSourceHost': serializer.toJson<String>(noteSourceHost),
      'noteId': serializer.toJson<String>(noteId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'receivedAt': serializer.toJson<DateTime>(receivedAt),
    };
  }

  TimelineItemRow copyWith({
    String? accountId,
    String? timelineKey,
    String? noteSourceHost,
    String? noteId,
    DateTime? createdAt,
    DateTime? receivedAt,
  }) => TimelineItemRow(
    accountId: accountId ?? this.accountId,
    timelineKey: timelineKey ?? this.timelineKey,
    noteSourceHost: noteSourceHost ?? this.noteSourceHost,
    noteId: noteId ?? this.noteId,
    createdAt: createdAt ?? this.createdAt,
    receivedAt: receivedAt ?? this.receivedAt,
  );
  TimelineItemRow copyWithCompanion(TimelineItemsCompanion data) {
    return TimelineItemRow(
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      timelineKey:
          data.timelineKey.present ? data.timelineKey.value : this.timelineKey,
      noteSourceHost:
          data.noteSourceHost.present
              ? data.noteSourceHost.value
              : this.noteSourceHost,
      noteId: data.noteId.present ? data.noteId.value : this.noteId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      receivedAt:
          data.receivedAt.present ? data.receivedAt.value : this.receivedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TimelineItemRow(')
          ..write('accountId: $accountId, ')
          ..write('timelineKey: $timelineKey, ')
          ..write('noteSourceHost: $noteSourceHost, ')
          ..write('noteId: $noteId, ')
          ..write('createdAt: $createdAt, ')
          ..write('receivedAt: $receivedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    accountId,
    timelineKey,
    noteSourceHost,
    noteId,
    createdAt,
    receivedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TimelineItemRow &&
          other.accountId == this.accountId &&
          other.timelineKey == this.timelineKey &&
          other.noteSourceHost == this.noteSourceHost &&
          other.noteId == this.noteId &&
          other.createdAt == this.createdAt &&
          other.receivedAt == this.receivedAt);
}

class TimelineItemsCompanion extends UpdateCompanion<TimelineItemRow> {
  final Value<String> accountId;
  final Value<String> timelineKey;
  final Value<String> noteSourceHost;
  final Value<String> noteId;
  final Value<DateTime> createdAt;
  final Value<DateTime> receivedAt;
  final Value<int> rowid;
  const TimelineItemsCompanion({
    this.accountId = const Value.absent(),
    this.timelineKey = const Value.absent(),
    this.noteSourceHost = const Value.absent(),
    this.noteId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.receivedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TimelineItemsCompanion.insert({
    required String accountId,
    required String timelineKey,
    required String noteSourceHost,
    required String noteId,
    required DateTime createdAt,
    required DateTime receivedAt,
    this.rowid = const Value.absent(),
  }) : accountId = Value(accountId),
       timelineKey = Value(timelineKey),
       noteSourceHost = Value(noteSourceHost),
       noteId = Value(noteId),
       createdAt = Value(createdAt),
       receivedAt = Value(receivedAt);
  static Insertable<TimelineItemRow> custom({
    Expression<String>? accountId,
    Expression<String>? timelineKey,
    Expression<String>? noteSourceHost,
    Expression<String>? noteId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? receivedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (accountId != null) 'account_id': accountId,
      if (timelineKey != null) 'timeline_key': timelineKey,
      if (noteSourceHost != null) 'note_source_host': noteSourceHost,
      if (noteId != null) 'note_id': noteId,
      if (createdAt != null) 'created_at': createdAt,
      if (receivedAt != null) 'received_at': receivedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TimelineItemsCompanion copyWith({
    Value<String>? accountId,
    Value<String>? timelineKey,
    Value<String>? noteSourceHost,
    Value<String>? noteId,
    Value<DateTime>? createdAt,
    Value<DateTime>? receivedAt,
    Value<int>? rowid,
  }) {
    return TimelineItemsCompanion(
      accountId: accountId ?? this.accountId,
      timelineKey: timelineKey ?? this.timelineKey,
      noteSourceHost: noteSourceHost ?? this.noteSourceHost,
      noteId: noteId ?? this.noteId,
      createdAt: createdAt ?? this.createdAt,
      receivedAt: receivedAt ?? this.receivedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (timelineKey.present) {
      map['timeline_key'] = Variable<String>(timelineKey.value);
    }
    if (noteSourceHost.present) {
      map['note_source_host'] = Variable<String>(noteSourceHost.value);
    }
    if (noteId.present) {
      map['note_id'] = Variable<String>(noteId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (receivedAt.present) {
      map['received_at'] = Variable<DateTime>(receivedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TimelineItemsCompanion(')
          ..write('accountId: $accountId, ')
          ..write('timelineKey: $timelineKey, ')
          ..write('noteSourceHost: $noteSourceHost, ')
          ..write('noteId: $noteId, ')
          ..write('createdAt: $createdAt, ')
          ..write('receivedAt: $receivedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $HeightCacheTable extends HeightCache
    with TableInfo<$HeightCacheTable, HeightCacheRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HeightCacheTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _hostMeta = const VerificationMeta('host');
  @override
  late final GeneratedColumn<String> host = GeneratedColumn<String>(
    'host',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteIdMeta = const VerificationMeta('noteId');
  @override
  late final GeneratedColumn<String> noteId = GeneratedColumn<String>(
    'note_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _revisionMeta = const VerificationMeta(
    'revision',
  );
  @override
  late final GeneratedColumn<int> revision = GeneratedColumn<int>(
    'revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _widthMeta = const VerificationMeta('width');
  @override
  late final GeneratedColumn<double> width = GeneratedColumn<double>(
    'width',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _textScaleMeta = const VerificationMeta(
    'textScale',
  );
  @override
  late final GeneratedColumn<double> textScale = GeneratedColumn<double>(
    'text_scale',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _themeIdMeta = const VerificationMeta(
    'themeId',
  );
  @override
  late final GeneratedColumn<String> themeId = GeneratedColumn<String>(
    'theme_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cwExpandedMeta = const VerificationMeta(
    'cwExpanded',
  );
  @override
  late final GeneratedColumn<bool> cwExpanded = GeneratedColumn<bool>(
    'cw_expanded',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("cw_expanded" IN (0, 1))',
    ),
  );
  static const VerificationMeta _mfmSettingsHashMeta = const VerificationMeta(
    'mfmSettingsHash',
  );
  @override
  late final GeneratedColumn<String> mfmSettingsHash = GeneratedColumn<String>(
    'mfm_settings_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _heightMeta = const VerificationMeta('height');
  @override
  late final GeneratedColumn<double> height = GeneratedColumn<double>(
    'height',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _computedAtMeta = const VerificationMeta(
    'computedAt',
  );
  @override
  late final GeneratedColumn<DateTime> computedAt = GeneratedColumn<DateTime>(
    'computed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    host,
    noteId,
    revision,
    width,
    textScale,
    themeId,
    cwExpanded,
    mfmSettingsHash,
    height,
    computedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'height_cache';
  @override
  VerificationContext validateIntegrity(
    Insertable<HeightCacheRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('host')) {
      context.handle(
        _hostMeta,
        host.isAcceptableOrUnknown(data['host']!, _hostMeta),
      );
    } else if (isInserting) {
      context.missing(_hostMeta);
    }
    if (data.containsKey('note_id')) {
      context.handle(
        _noteIdMeta,
        noteId.isAcceptableOrUnknown(data['note_id']!, _noteIdMeta),
      );
    } else if (isInserting) {
      context.missing(_noteIdMeta);
    }
    if (data.containsKey('revision')) {
      context.handle(
        _revisionMeta,
        revision.isAcceptableOrUnknown(data['revision']!, _revisionMeta),
      );
    } else if (isInserting) {
      context.missing(_revisionMeta);
    }
    if (data.containsKey('width')) {
      context.handle(
        _widthMeta,
        width.isAcceptableOrUnknown(data['width']!, _widthMeta),
      );
    } else if (isInserting) {
      context.missing(_widthMeta);
    }
    if (data.containsKey('text_scale')) {
      context.handle(
        _textScaleMeta,
        textScale.isAcceptableOrUnknown(data['text_scale']!, _textScaleMeta),
      );
    } else if (isInserting) {
      context.missing(_textScaleMeta);
    }
    if (data.containsKey('theme_id')) {
      context.handle(
        _themeIdMeta,
        themeId.isAcceptableOrUnknown(data['theme_id']!, _themeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_themeIdMeta);
    }
    if (data.containsKey('cw_expanded')) {
      context.handle(
        _cwExpandedMeta,
        cwExpanded.isAcceptableOrUnknown(data['cw_expanded']!, _cwExpandedMeta),
      );
    } else if (isInserting) {
      context.missing(_cwExpandedMeta);
    }
    if (data.containsKey('mfm_settings_hash')) {
      context.handle(
        _mfmSettingsHashMeta,
        mfmSettingsHash.isAcceptableOrUnknown(
          data['mfm_settings_hash']!,
          _mfmSettingsHashMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_mfmSettingsHashMeta);
    }
    if (data.containsKey('height')) {
      context.handle(
        _heightMeta,
        height.isAcceptableOrUnknown(data['height']!, _heightMeta),
      );
    } else if (isInserting) {
      context.missing(_heightMeta);
    }
    if (data.containsKey('computed_at')) {
      context.handle(
        _computedAtMeta,
        computedAt.isAcceptableOrUnknown(data['computed_at']!, _computedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_computedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {
    host,
    noteId,
    revision,
    width,
    textScale,
    themeId,
    cwExpanded,
    mfmSettingsHash,
  };
  @override
  HeightCacheRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HeightCacheRow(
      host:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}host'],
          )!,
      noteId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}note_id'],
          )!,
      revision:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}revision'],
          )!,
      width:
          attachedDatabase.typeMapping.read(
            DriftSqlType.double,
            data['${effectivePrefix}width'],
          )!,
      textScale:
          attachedDatabase.typeMapping.read(
            DriftSqlType.double,
            data['${effectivePrefix}text_scale'],
          )!,
      themeId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}theme_id'],
          )!,
      cwExpanded:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}cw_expanded'],
          )!,
      mfmSettingsHash:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}mfm_settings_hash'],
          )!,
      height:
          attachedDatabase.typeMapping.read(
            DriftSqlType.double,
            data['${effectivePrefix}height'],
          )!,
      computedAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}computed_at'],
          )!,
    );
  }

  @override
  $HeightCacheTable createAlias(String alias) {
    return $HeightCacheTable(attachedDatabase, alias);
  }
}

class HeightCacheRow extends DataClass implements Insertable<HeightCacheRow> {
  /// Composite cache key per design doc §11.
  final String host;
  final String noteId;
  final int revision;
  final double width;
  final double textScale;
  final String themeId;
  final bool cwExpanded;
  final String mfmSettingsHash;
  final double height;
  final DateTime computedAt;
  const HeightCacheRow({
    required this.host,
    required this.noteId,
    required this.revision,
    required this.width,
    required this.textScale,
    required this.themeId,
    required this.cwExpanded,
    required this.mfmSettingsHash,
    required this.height,
    required this.computedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['host'] = Variable<String>(host);
    map['note_id'] = Variable<String>(noteId);
    map['revision'] = Variable<int>(revision);
    map['width'] = Variable<double>(width);
    map['text_scale'] = Variable<double>(textScale);
    map['theme_id'] = Variable<String>(themeId);
    map['cw_expanded'] = Variable<bool>(cwExpanded);
    map['mfm_settings_hash'] = Variable<String>(mfmSettingsHash);
    map['height'] = Variable<double>(height);
    map['computed_at'] = Variable<DateTime>(computedAt);
    return map;
  }

  HeightCacheCompanion toCompanion(bool nullToAbsent) {
    return HeightCacheCompanion(
      host: Value(host),
      noteId: Value(noteId),
      revision: Value(revision),
      width: Value(width),
      textScale: Value(textScale),
      themeId: Value(themeId),
      cwExpanded: Value(cwExpanded),
      mfmSettingsHash: Value(mfmSettingsHash),
      height: Value(height),
      computedAt: Value(computedAt),
    );
  }

  factory HeightCacheRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HeightCacheRow(
      host: serializer.fromJson<String>(json['host']),
      noteId: serializer.fromJson<String>(json['noteId']),
      revision: serializer.fromJson<int>(json['revision']),
      width: serializer.fromJson<double>(json['width']),
      textScale: serializer.fromJson<double>(json['textScale']),
      themeId: serializer.fromJson<String>(json['themeId']),
      cwExpanded: serializer.fromJson<bool>(json['cwExpanded']),
      mfmSettingsHash: serializer.fromJson<String>(json['mfmSettingsHash']),
      height: serializer.fromJson<double>(json['height']),
      computedAt: serializer.fromJson<DateTime>(json['computedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'host': serializer.toJson<String>(host),
      'noteId': serializer.toJson<String>(noteId),
      'revision': serializer.toJson<int>(revision),
      'width': serializer.toJson<double>(width),
      'textScale': serializer.toJson<double>(textScale),
      'themeId': serializer.toJson<String>(themeId),
      'cwExpanded': serializer.toJson<bool>(cwExpanded),
      'mfmSettingsHash': serializer.toJson<String>(mfmSettingsHash),
      'height': serializer.toJson<double>(height),
      'computedAt': serializer.toJson<DateTime>(computedAt),
    };
  }

  HeightCacheRow copyWith({
    String? host,
    String? noteId,
    int? revision,
    double? width,
    double? textScale,
    String? themeId,
    bool? cwExpanded,
    String? mfmSettingsHash,
    double? height,
    DateTime? computedAt,
  }) => HeightCacheRow(
    host: host ?? this.host,
    noteId: noteId ?? this.noteId,
    revision: revision ?? this.revision,
    width: width ?? this.width,
    textScale: textScale ?? this.textScale,
    themeId: themeId ?? this.themeId,
    cwExpanded: cwExpanded ?? this.cwExpanded,
    mfmSettingsHash: mfmSettingsHash ?? this.mfmSettingsHash,
    height: height ?? this.height,
    computedAt: computedAt ?? this.computedAt,
  );
  HeightCacheRow copyWithCompanion(HeightCacheCompanion data) {
    return HeightCacheRow(
      host: data.host.present ? data.host.value : this.host,
      noteId: data.noteId.present ? data.noteId.value : this.noteId,
      revision: data.revision.present ? data.revision.value : this.revision,
      width: data.width.present ? data.width.value : this.width,
      textScale: data.textScale.present ? data.textScale.value : this.textScale,
      themeId: data.themeId.present ? data.themeId.value : this.themeId,
      cwExpanded:
          data.cwExpanded.present ? data.cwExpanded.value : this.cwExpanded,
      mfmSettingsHash:
          data.mfmSettingsHash.present
              ? data.mfmSettingsHash.value
              : this.mfmSettingsHash,
      height: data.height.present ? data.height.value : this.height,
      computedAt:
          data.computedAt.present ? data.computedAt.value : this.computedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HeightCacheRow(')
          ..write('host: $host, ')
          ..write('noteId: $noteId, ')
          ..write('revision: $revision, ')
          ..write('width: $width, ')
          ..write('textScale: $textScale, ')
          ..write('themeId: $themeId, ')
          ..write('cwExpanded: $cwExpanded, ')
          ..write('mfmSettingsHash: $mfmSettingsHash, ')
          ..write('height: $height, ')
          ..write('computedAt: $computedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    host,
    noteId,
    revision,
    width,
    textScale,
    themeId,
    cwExpanded,
    mfmSettingsHash,
    height,
    computedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HeightCacheRow &&
          other.host == this.host &&
          other.noteId == this.noteId &&
          other.revision == this.revision &&
          other.width == this.width &&
          other.textScale == this.textScale &&
          other.themeId == this.themeId &&
          other.cwExpanded == this.cwExpanded &&
          other.mfmSettingsHash == this.mfmSettingsHash &&
          other.height == this.height &&
          other.computedAt == this.computedAt);
}

class HeightCacheCompanion extends UpdateCompanion<HeightCacheRow> {
  final Value<String> host;
  final Value<String> noteId;
  final Value<int> revision;
  final Value<double> width;
  final Value<double> textScale;
  final Value<String> themeId;
  final Value<bool> cwExpanded;
  final Value<String> mfmSettingsHash;
  final Value<double> height;
  final Value<DateTime> computedAt;
  final Value<int> rowid;
  const HeightCacheCompanion({
    this.host = const Value.absent(),
    this.noteId = const Value.absent(),
    this.revision = const Value.absent(),
    this.width = const Value.absent(),
    this.textScale = const Value.absent(),
    this.themeId = const Value.absent(),
    this.cwExpanded = const Value.absent(),
    this.mfmSettingsHash = const Value.absent(),
    this.height = const Value.absent(),
    this.computedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HeightCacheCompanion.insert({
    required String host,
    required String noteId,
    required int revision,
    required double width,
    required double textScale,
    required String themeId,
    required bool cwExpanded,
    required String mfmSettingsHash,
    required double height,
    required DateTime computedAt,
    this.rowid = const Value.absent(),
  }) : host = Value(host),
       noteId = Value(noteId),
       revision = Value(revision),
       width = Value(width),
       textScale = Value(textScale),
       themeId = Value(themeId),
       cwExpanded = Value(cwExpanded),
       mfmSettingsHash = Value(mfmSettingsHash),
       height = Value(height),
       computedAt = Value(computedAt);
  static Insertable<HeightCacheRow> custom({
    Expression<String>? host,
    Expression<String>? noteId,
    Expression<int>? revision,
    Expression<double>? width,
    Expression<double>? textScale,
    Expression<String>? themeId,
    Expression<bool>? cwExpanded,
    Expression<String>? mfmSettingsHash,
    Expression<double>? height,
    Expression<DateTime>? computedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (host != null) 'host': host,
      if (noteId != null) 'note_id': noteId,
      if (revision != null) 'revision': revision,
      if (width != null) 'width': width,
      if (textScale != null) 'text_scale': textScale,
      if (themeId != null) 'theme_id': themeId,
      if (cwExpanded != null) 'cw_expanded': cwExpanded,
      if (mfmSettingsHash != null) 'mfm_settings_hash': mfmSettingsHash,
      if (height != null) 'height': height,
      if (computedAt != null) 'computed_at': computedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HeightCacheCompanion copyWith({
    Value<String>? host,
    Value<String>? noteId,
    Value<int>? revision,
    Value<double>? width,
    Value<double>? textScale,
    Value<String>? themeId,
    Value<bool>? cwExpanded,
    Value<String>? mfmSettingsHash,
    Value<double>? height,
    Value<DateTime>? computedAt,
    Value<int>? rowid,
  }) {
    return HeightCacheCompanion(
      host: host ?? this.host,
      noteId: noteId ?? this.noteId,
      revision: revision ?? this.revision,
      width: width ?? this.width,
      textScale: textScale ?? this.textScale,
      themeId: themeId ?? this.themeId,
      cwExpanded: cwExpanded ?? this.cwExpanded,
      mfmSettingsHash: mfmSettingsHash ?? this.mfmSettingsHash,
      height: height ?? this.height,
      computedAt: computedAt ?? this.computedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (host.present) {
      map['host'] = Variable<String>(host.value);
    }
    if (noteId.present) {
      map['note_id'] = Variable<String>(noteId.value);
    }
    if (revision.present) {
      map['revision'] = Variable<int>(revision.value);
    }
    if (width.present) {
      map['width'] = Variable<double>(width.value);
    }
    if (textScale.present) {
      map['text_scale'] = Variable<double>(textScale.value);
    }
    if (themeId.present) {
      map['theme_id'] = Variable<String>(themeId.value);
    }
    if (cwExpanded.present) {
      map['cw_expanded'] = Variable<bool>(cwExpanded.value);
    }
    if (mfmSettingsHash.present) {
      map['mfm_settings_hash'] = Variable<String>(mfmSettingsHash.value);
    }
    if (height.present) {
      map['height'] = Variable<double>(height.value);
    }
    if (computedAt.present) {
      map['computed_at'] = Variable<DateTime>(computedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HeightCacheCompanion(')
          ..write('host: $host, ')
          ..write('noteId: $noteId, ')
          ..write('revision: $revision, ')
          ..write('width: $width, ')
          ..write('textScale: $textScale, ')
          ..write('themeId: $themeId, ')
          ..write('cwExpanded: $cwExpanded, ')
          ..write('mfmSettingsHash: $mfmSettingsHash, ')
          ..write('height: $height, ')
          ..write('computedAt: $computedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReactionRecentsTable extends ReactionRecents
    with TableInfo<$ReactionRecentsTable, ReactionRecentRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReactionRecentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reactionKeyMeta = const VerificationMeta(
    'reactionKey',
  );
  @override
  late final GeneratedColumn<String> reactionKey = GeneratedColumn<String>(
    'reaction_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _useCountMeta = const VerificationMeta(
    'useCount',
  );
  @override
  late final GeneratedColumn<int> useCount = GeneratedColumn<int>(
    'use_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastUsedAtMeta = const VerificationMeta(
    'lastUsedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastUsedAt = GeneratedColumn<DateTime>(
    'last_used_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    accountId,
    reactionKey,
    useCount,
    lastUsedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reaction_recents';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReactionRecentRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('reaction_key')) {
      context.handle(
        _reactionKeyMeta,
        reactionKey.isAcceptableOrUnknown(
          data['reaction_key']!,
          _reactionKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_reactionKeyMeta);
    }
    if (data.containsKey('use_count')) {
      context.handle(
        _useCountMeta,
        useCount.isAcceptableOrUnknown(data['use_count']!, _useCountMeta),
      );
    }
    if (data.containsKey('last_used_at')) {
      context.handle(
        _lastUsedAtMeta,
        lastUsedAt.isAcceptableOrUnknown(
          data['last_used_at']!,
          _lastUsedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastUsedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {accountId, reactionKey};
  @override
  ReactionRecentRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReactionRecentRow(
      accountId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}account_id'],
          )!,
      reactionKey:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}reaction_key'],
          )!,
      useCount:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}use_count'],
          )!,
      lastUsedAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}last_used_at'],
          )!,
    );
  }

  @override
  $ReactionRecentsTable createAlias(String alias) {
    return $ReactionRecentsTable(attachedDatabase, alias);
  }
}

class ReactionRecentRow extends DataClass
    implements Insertable<ReactionRecentRow> {
  /// Owning account so each account remembers its own picker recents.
  final String accountId;

  /// Same `key` shape as `Reaction.key` (unicode codepoint sequence
  /// or `:name@host:` for custom emoji).
  final String reactionKey;
  final int useCount;
  final DateTime lastUsedAt;
  const ReactionRecentRow({
    required this.accountId,
    required this.reactionKey,
    required this.useCount,
    required this.lastUsedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['account_id'] = Variable<String>(accountId);
    map['reaction_key'] = Variable<String>(reactionKey);
    map['use_count'] = Variable<int>(useCount);
    map['last_used_at'] = Variable<DateTime>(lastUsedAt);
    return map;
  }

  ReactionRecentsCompanion toCompanion(bool nullToAbsent) {
    return ReactionRecentsCompanion(
      accountId: Value(accountId),
      reactionKey: Value(reactionKey),
      useCount: Value(useCount),
      lastUsedAt: Value(lastUsedAt),
    );
  }

  factory ReactionRecentRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReactionRecentRow(
      accountId: serializer.fromJson<String>(json['accountId']),
      reactionKey: serializer.fromJson<String>(json['reactionKey']),
      useCount: serializer.fromJson<int>(json['useCount']),
      lastUsedAt: serializer.fromJson<DateTime>(json['lastUsedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'accountId': serializer.toJson<String>(accountId),
      'reactionKey': serializer.toJson<String>(reactionKey),
      'useCount': serializer.toJson<int>(useCount),
      'lastUsedAt': serializer.toJson<DateTime>(lastUsedAt),
    };
  }

  ReactionRecentRow copyWith({
    String? accountId,
    String? reactionKey,
    int? useCount,
    DateTime? lastUsedAt,
  }) => ReactionRecentRow(
    accountId: accountId ?? this.accountId,
    reactionKey: reactionKey ?? this.reactionKey,
    useCount: useCount ?? this.useCount,
    lastUsedAt: lastUsedAt ?? this.lastUsedAt,
  );
  ReactionRecentRow copyWithCompanion(ReactionRecentsCompanion data) {
    return ReactionRecentRow(
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      reactionKey:
          data.reactionKey.present ? data.reactionKey.value : this.reactionKey,
      useCount: data.useCount.present ? data.useCount.value : this.useCount,
      lastUsedAt:
          data.lastUsedAt.present ? data.lastUsedAt.value : this.lastUsedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReactionRecentRow(')
          ..write('accountId: $accountId, ')
          ..write('reactionKey: $reactionKey, ')
          ..write('useCount: $useCount, ')
          ..write('lastUsedAt: $lastUsedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(accountId, reactionKey, useCount, lastUsedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReactionRecentRow &&
          other.accountId == this.accountId &&
          other.reactionKey == this.reactionKey &&
          other.useCount == this.useCount &&
          other.lastUsedAt == this.lastUsedAt);
}

class ReactionRecentsCompanion extends UpdateCompanion<ReactionRecentRow> {
  final Value<String> accountId;
  final Value<String> reactionKey;
  final Value<int> useCount;
  final Value<DateTime> lastUsedAt;
  final Value<int> rowid;
  const ReactionRecentsCompanion({
    this.accountId = const Value.absent(),
    this.reactionKey = const Value.absent(),
    this.useCount = const Value.absent(),
    this.lastUsedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReactionRecentsCompanion.insert({
    required String accountId,
    required String reactionKey,
    this.useCount = const Value.absent(),
    required DateTime lastUsedAt,
    this.rowid = const Value.absent(),
  }) : accountId = Value(accountId),
       reactionKey = Value(reactionKey),
       lastUsedAt = Value(lastUsedAt);
  static Insertable<ReactionRecentRow> custom({
    Expression<String>? accountId,
    Expression<String>? reactionKey,
    Expression<int>? useCount,
    Expression<DateTime>? lastUsedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (accountId != null) 'account_id': accountId,
      if (reactionKey != null) 'reaction_key': reactionKey,
      if (useCount != null) 'use_count': useCount,
      if (lastUsedAt != null) 'last_used_at': lastUsedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReactionRecentsCompanion copyWith({
    Value<String>? accountId,
    Value<String>? reactionKey,
    Value<int>? useCount,
    Value<DateTime>? lastUsedAt,
    Value<int>? rowid,
  }) {
    return ReactionRecentsCompanion(
      accountId: accountId ?? this.accountId,
      reactionKey: reactionKey ?? this.reactionKey,
      useCount: useCount ?? this.useCount,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (reactionKey.present) {
      map['reaction_key'] = Variable<String>(reactionKey.value);
    }
    if (useCount.present) {
      map['use_count'] = Variable<int>(useCount.value);
    }
    if (lastUsedAt.present) {
      map['last_used_at'] = Variable<DateTime>(lastUsedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReactionRecentsCompanion(')
          ..write('accountId: $accountId, ')
          ..write('reactionKey: $reactionKey, ')
          ..write('useCount: $useCount, ')
          ..write('lastUsedAt: $lastUsedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DraftsTable extends Drafts with TableInfo<$DraftsTable, DraftRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DraftsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cwMeta = const VerificationMeta('cw');
  @override
  late final GeneratedColumn<String> cw = GeneratedColumn<String>(
    'cw',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _visibilityMeta = const VerificationMeta(
    'visibility',
  );
  @override
  late final GeneratedColumn<String> visibility = GeneratedColumn<String>(
    'visibility',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('public'),
  );
  static const VerificationMeta _localOnlyMeta = const VerificationMeta(
    'localOnly',
  );
  @override
  late final GeneratedColumn<bool> localOnly = GeneratedColumn<bool>(
    'local_only',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("local_only" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _replyIdMeta = const VerificationMeta(
    'replyId',
  );
  @override
  late final GeneratedColumn<String> replyId = GeneratedColumn<String>(
    'reply_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _renoteIdMeta = const VerificationMeta(
    'renoteId',
  );
  @override
  late final GeneratedColumn<String> renoteId = GeneratedColumn<String>(
    'renote_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceNoteUriMeta = const VerificationMeta(
    'sourceNoteUri',
  );
  @override
  late final GeneratedColumn<String> sourceNoteUri = GeneratedColumn<String>(
    'source_note_uri',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceHostMeta = const VerificationMeta(
    'sourceHost',
  );
  @override
  late final GeneratedColumn<String> sourceHost = GeneratedColumn<String>(
    'source_host',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fileIdsJsonMeta = const VerificationMeta(
    'fileIdsJson',
  );
  @override
  late final GeneratedColumn<String> fileIdsJson = GeneratedColumn<String>(
    'file_ids_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _channelIdMeta = const VerificationMeta(
    'channelId',
  );
  @override
  late final GeneratedColumn<String> channelId = GeneratedColumn<String>(
    'channel_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _channelNameMeta = const VerificationMeta(
    'channelName',
  );
  @override
  late final GeneratedColumn<String> channelName = GeneratedColumn<String>(
    'channel_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    accountId,
    body,
    cw,
    visibility,
    localOnly,
    replyId,
    renoteId,
    sourceNoteUri,
    sourceHost,
    fileIdsJson,
    channelId,
    channelName,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'drafts';
  @override
  VerificationContext validateIntegrity(
    Insertable<DraftRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('text')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['text']!, _bodyMeta),
      );
    }
    if (data.containsKey('cw')) {
      context.handle(_cwMeta, cw.isAcceptableOrUnknown(data['cw']!, _cwMeta));
    }
    if (data.containsKey('visibility')) {
      context.handle(
        _visibilityMeta,
        visibility.isAcceptableOrUnknown(data['visibility']!, _visibilityMeta),
      );
    }
    if (data.containsKey('local_only')) {
      context.handle(
        _localOnlyMeta,
        localOnly.isAcceptableOrUnknown(data['local_only']!, _localOnlyMeta),
      );
    }
    if (data.containsKey('reply_id')) {
      context.handle(
        _replyIdMeta,
        replyId.isAcceptableOrUnknown(data['reply_id']!, _replyIdMeta),
      );
    }
    if (data.containsKey('renote_id')) {
      context.handle(
        _renoteIdMeta,
        renoteId.isAcceptableOrUnknown(data['renote_id']!, _renoteIdMeta),
      );
    }
    if (data.containsKey('source_note_uri')) {
      context.handle(
        _sourceNoteUriMeta,
        sourceNoteUri.isAcceptableOrUnknown(
          data['source_note_uri']!,
          _sourceNoteUriMeta,
        ),
      );
    }
    if (data.containsKey('source_host')) {
      context.handle(
        _sourceHostMeta,
        sourceHost.isAcceptableOrUnknown(data['source_host']!, _sourceHostMeta),
      );
    }
    if (data.containsKey('file_ids_json')) {
      context.handle(
        _fileIdsJsonMeta,
        fileIdsJson.isAcceptableOrUnknown(
          data['file_ids_json']!,
          _fileIdsJsonMeta,
        ),
      );
    }
    if (data.containsKey('channel_id')) {
      context.handle(
        _channelIdMeta,
        channelId.isAcceptableOrUnknown(data['channel_id']!, _channelIdMeta),
      );
    }
    if (data.containsKey('channel_name')) {
      context.handle(
        _channelNameMeta,
        channelName.isAcceptableOrUnknown(
          data['channel_name']!,
          _channelNameMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DraftRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DraftRow(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}id'],
          )!,
      accountId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}account_id'],
          )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}text'],
      ),
      cw: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cw'],
      ),
      visibility:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}visibility'],
          )!,
      localOnly:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}local_only'],
          )!,
      replyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reply_id'],
      ),
      renoteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}renote_id'],
      ),
      sourceNoteUri: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_note_uri'],
      ),
      sourceHost: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_host'],
      ),
      fileIdsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_ids_json'],
      ),
      channelId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}channel_id'],
      ),
      channelName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}channel_name'],
      ),
      createdAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}created_at'],
          )!,
      updatedAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}updated_at'],
          )!,
    );
  }

  @override
  $DraftsTable createAlias(String alias) {
    return $DraftsTable(attachedDatabase, alias);
  }
}

class DraftRow extends DataClass implements Insertable<DraftRow> {
  /// v4 UUID.
  final String id;

  /// Owning account ("host:userId"). A draft is only visible to its
  /// owning account so two accounts on the same device don't pollute
  /// each other's draft list.
  final String accountId;

  /// Renamed from `text` because `Table.text()` is the column-builder
  /// in Drift and would shadow the field.
  final String? body;
  final String? cw;

  /// `public` / `home` / `followers` / `specified`.
  final String visibility;
  final bool localOnly;
  final String? replyId;
  final String? renoteId;

  /// Canonical ActivityPub URI of the source note when this draft is a
  /// reply or quote (`Note.originId`). Stored alongside replyId/renoteId
  /// because those are account-local ids — switching accounts in the
  /// composer requires re-resolving via `ap/show`, which keys on URI.
  final String? sourceNoteUri;

  /// host of the active account at the time the draft was saved
  /// (`accountId`'s host component) — kept so a stale `replyId` from
  /// before an account change can be discarded if the account isn't
  /// available any more.
  final String? sourceHost;

  /// JSON-encoded `List<String>` of drive file ids already uploaded.
  final String? fileIdsJson;

  /// Target channel (local to the owning account's server) when the
  /// draft was addressed to a channel. `channelName` is denormalised
  /// so the chip renders on resume without a `channels/show` round
  /// trip.
  final String? channelId;
  final String? channelName;
  final DateTime createdAt;
  final DateTime updatedAt;
  const DraftRow({
    required this.id,
    required this.accountId,
    this.body,
    this.cw,
    required this.visibility,
    required this.localOnly,
    this.replyId,
    this.renoteId,
    this.sourceNoteUri,
    this.sourceHost,
    this.fileIdsJson,
    this.channelId,
    this.channelName,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['account_id'] = Variable<String>(accountId);
    if (!nullToAbsent || body != null) {
      map['text'] = Variable<String>(body);
    }
    if (!nullToAbsent || cw != null) {
      map['cw'] = Variable<String>(cw);
    }
    map['visibility'] = Variable<String>(visibility);
    map['local_only'] = Variable<bool>(localOnly);
    if (!nullToAbsent || replyId != null) {
      map['reply_id'] = Variable<String>(replyId);
    }
    if (!nullToAbsent || renoteId != null) {
      map['renote_id'] = Variable<String>(renoteId);
    }
    if (!nullToAbsent || sourceNoteUri != null) {
      map['source_note_uri'] = Variable<String>(sourceNoteUri);
    }
    if (!nullToAbsent || sourceHost != null) {
      map['source_host'] = Variable<String>(sourceHost);
    }
    if (!nullToAbsent || fileIdsJson != null) {
      map['file_ids_json'] = Variable<String>(fileIdsJson);
    }
    if (!nullToAbsent || channelId != null) {
      map['channel_id'] = Variable<String>(channelId);
    }
    if (!nullToAbsent || channelName != null) {
      map['channel_name'] = Variable<String>(channelName);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  DraftsCompanion toCompanion(bool nullToAbsent) {
    return DraftsCompanion(
      id: Value(id),
      accountId: Value(accountId),
      body: body == null && nullToAbsent ? const Value.absent() : Value(body),
      cw: cw == null && nullToAbsent ? const Value.absent() : Value(cw),
      visibility: Value(visibility),
      localOnly: Value(localOnly),
      replyId:
          replyId == null && nullToAbsent
              ? const Value.absent()
              : Value(replyId),
      renoteId:
          renoteId == null && nullToAbsent
              ? const Value.absent()
              : Value(renoteId),
      sourceNoteUri:
          sourceNoteUri == null && nullToAbsent
              ? const Value.absent()
              : Value(sourceNoteUri),
      sourceHost:
          sourceHost == null && nullToAbsent
              ? const Value.absent()
              : Value(sourceHost),
      fileIdsJson:
          fileIdsJson == null && nullToAbsent
              ? const Value.absent()
              : Value(fileIdsJson),
      channelId:
          channelId == null && nullToAbsent
              ? const Value.absent()
              : Value(channelId),
      channelName:
          channelName == null && nullToAbsent
              ? const Value.absent()
              : Value(channelName),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory DraftRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DraftRow(
      id: serializer.fromJson<String>(json['id']),
      accountId: serializer.fromJson<String>(json['accountId']),
      body: serializer.fromJson<String?>(json['body']),
      cw: serializer.fromJson<String?>(json['cw']),
      visibility: serializer.fromJson<String>(json['visibility']),
      localOnly: serializer.fromJson<bool>(json['localOnly']),
      replyId: serializer.fromJson<String?>(json['replyId']),
      renoteId: serializer.fromJson<String?>(json['renoteId']),
      sourceNoteUri: serializer.fromJson<String?>(json['sourceNoteUri']),
      sourceHost: serializer.fromJson<String?>(json['sourceHost']),
      fileIdsJson: serializer.fromJson<String?>(json['fileIdsJson']),
      channelId: serializer.fromJson<String?>(json['channelId']),
      channelName: serializer.fromJson<String?>(json['channelName']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'accountId': serializer.toJson<String>(accountId),
      'body': serializer.toJson<String?>(body),
      'cw': serializer.toJson<String?>(cw),
      'visibility': serializer.toJson<String>(visibility),
      'localOnly': serializer.toJson<bool>(localOnly),
      'replyId': serializer.toJson<String?>(replyId),
      'renoteId': serializer.toJson<String?>(renoteId),
      'sourceNoteUri': serializer.toJson<String?>(sourceNoteUri),
      'sourceHost': serializer.toJson<String?>(sourceHost),
      'fileIdsJson': serializer.toJson<String?>(fileIdsJson),
      'channelId': serializer.toJson<String?>(channelId),
      'channelName': serializer.toJson<String?>(channelName),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  DraftRow copyWith({
    String? id,
    String? accountId,
    Value<String?> body = const Value.absent(),
    Value<String?> cw = const Value.absent(),
    String? visibility,
    bool? localOnly,
    Value<String?> replyId = const Value.absent(),
    Value<String?> renoteId = const Value.absent(),
    Value<String?> sourceNoteUri = const Value.absent(),
    Value<String?> sourceHost = const Value.absent(),
    Value<String?> fileIdsJson = const Value.absent(),
    Value<String?> channelId = const Value.absent(),
    Value<String?> channelName = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => DraftRow(
    id: id ?? this.id,
    accountId: accountId ?? this.accountId,
    body: body.present ? body.value : this.body,
    cw: cw.present ? cw.value : this.cw,
    visibility: visibility ?? this.visibility,
    localOnly: localOnly ?? this.localOnly,
    replyId: replyId.present ? replyId.value : this.replyId,
    renoteId: renoteId.present ? renoteId.value : this.renoteId,
    sourceNoteUri:
        sourceNoteUri.present ? sourceNoteUri.value : this.sourceNoteUri,
    sourceHost: sourceHost.present ? sourceHost.value : this.sourceHost,
    fileIdsJson: fileIdsJson.present ? fileIdsJson.value : this.fileIdsJson,
    channelId: channelId.present ? channelId.value : this.channelId,
    channelName: channelName.present ? channelName.value : this.channelName,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  DraftRow copyWithCompanion(DraftsCompanion data) {
    return DraftRow(
      id: data.id.present ? data.id.value : this.id,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      body: data.body.present ? data.body.value : this.body,
      cw: data.cw.present ? data.cw.value : this.cw,
      visibility:
          data.visibility.present ? data.visibility.value : this.visibility,
      localOnly: data.localOnly.present ? data.localOnly.value : this.localOnly,
      replyId: data.replyId.present ? data.replyId.value : this.replyId,
      renoteId: data.renoteId.present ? data.renoteId.value : this.renoteId,
      sourceNoteUri:
          data.sourceNoteUri.present
              ? data.sourceNoteUri.value
              : this.sourceNoteUri,
      sourceHost:
          data.sourceHost.present ? data.sourceHost.value : this.sourceHost,
      fileIdsJson:
          data.fileIdsJson.present ? data.fileIdsJson.value : this.fileIdsJson,
      channelId: data.channelId.present ? data.channelId.value : this.channelId,
      channelName:
          data.channelName.present ? data.channelName.value : this.channelName,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DraftRow(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('body: $body, ')
          ..write('cw: $cw, ')
          ..write('visibility: $visibility, ')
          ..write('localOnly: $localOnly, ')
          ..write('replyId: $replyId, ')
          ..write('renoteId: $renoteId, ')
          ..write('sourceNoteUri: $sourceNoteUri, ')
          ..write('sourceHost: $sourceHost, ')
          ..write('fileIdsJson: $fileIdsJson, ')
          ..write('channelId: $channelId, ')
          ..write('channelName: $channelName, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    accountId,
    body,
    cw,
    visibility,
    localOnly,
    replyId,
    renoteId,
    sourceNoteUri,
    sourceHost,
    fileIdsJson,
    channelId,
    channelName,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DraftRow &&
          other.id == this.id &&
          other.accountId == this.accountId &&
          other.body == this.body &&
          other.cw == this.cw &&
          other.visibility == this.visibility &&
          other.localOnly == this.localOnly &&
          other.replyId == this.replyId &&
          other.renoteId == this.renoteId &&
          other.sourceNoteUri == this.sourceNoteUri &&
          other.sourceHost == this.sourceHost &&
          other.fileIdsJson == this.fileIdsJson &&
          other.channelId == this.channelId &&
          other.channelName == this.channelName &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class DraftsCompanion extends UpdateCompanion<DraftRow> {
  final Value<String> id;
  final Value<String> accountId;
  final Value<String?> body;
  final Value<String?> cw;
  final Value<String> visibility;
  final Value<bool> localOnly;
  final Value<String?> replyId;
  final Value<String?> renoteId;
  final Value<String?> sourceNoteUri;
  final Value<String?> sourceHost;
  final Value<String?> fileIdsJson;
  final Value<String?> channelId;
  final Value<String?> channelName;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const DraftsCompanion({
    this.id = const Value.absent(),
    this.accountId = const Value.absent(),
    this.body = const Value.absent(),
    this.cw = const Value.absent(),
    this.visibility = const Value.absent(),
    this.localOnly = const Value.absent(),
    this.replyId = const Value.absent(),
    this.renoteId = const Value.absent(),
    this.sourceNoteUri = const Value.absent(),
    this.sourceHost = const Value.absent(),
    this.fileIdsJson = const Value.absent(),
    this.channelId = const Value.absent(),
    this.channelName = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DraftsCompanion.insert({
    required String id,
    required String accountId,
    this.body = const Value.absent(),
    this.cw = const Value.absent(),
    this.visibility = const Value.absent(),
    this.localOnly = const Value.absent(),
    this.replyId = const Value.absent(),
    this.renoteId = const Value.absent(),
    this.sourceNoteUri = const Value.absent(),
    this.sourceHost = const Value.absent(),
    this.fileIdsJson = const Value.absent(),
    this.channelId = const Value.absent(),
    this.channelName = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       accountId = Value(accountId),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<DraftRow> custom({
    Expression<String>? id,
    Expression<String>? accountId,
    Expression<String>? body,
    Expression<String>? cw,
    Expression<String>? visibility,
    Expression<bool>? localOnly,
    Expression<String>? replyId,
    Expression<String>? renoteId,
    Expression<String>? sourceNoteUri,
    Expression<String>? sourceHost,
    Expression<String>? fileIdsJson,
    Expression<String>? channelId,
    Expression<String>? channelName,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (accountId != null) 'account_id': accountId,
      if (body != null) 'text': body,
      if (cw != null) 'cw': cw,
      if (visibility != null) 'visibility': visibility,
      if (localOnly != null) 'local_only': localOnly,
      if (replyId != null) 'reply_id': replyId,
      if (renoteId != null) 'renote_id': renoteId,
      if (sourceNoteUri != null) 'source_note_uri': sourceNoteUri,
      if (sourceHost != null) 'source_host': sourceHost,
      if (fileIdsJson != null) 'file_ids_json': fileIdsJson,
      if (channelId != null) 'channel_id': channelId,
      if (channelName != null) 'channel_name': channelName,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DraftsCompanion copyWith({
    Value<String>? id,
    Value<String>? accountId,
    Value<String?>? body,
    Value<String?>? cw,
    Value<String>? visibility,
    Value<bool>? localOnly,
    Value<String?>? replyId,
    Value<String?>? renoteId,
    Value<String?>? sourceNoteUri,
    Value<String?>? sourceHost,
    Value<String?>? fileIdsJson,
    Value<String?>? channelId,
    Value<String?>? channelName,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return DraftsCompanion(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      body: body ?? this.body,
      cw: cw ?? this.cw,
      visibility: visibility ?? this.visibility,
      localOnly: localOnly ?? this.localOnly,
      replyId: replyId ?? this.replyId,
      renoteId: renoteId ?? this.renoteId,
      sourceNoteUri: sourceNoteUri ?? this.sourceNoteUri,
      sourceHost: sourceHost ?? this.sourceHost,
      fileIdsJson: fileIdsJson ?? this.fileIdsJson,
      channelId: channelId ?? this.channelId,
      channelName: channelName ?? this.channelName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (body.present) {
      map['text'] = Variable<String>(body.value);
    }
    if (cw.present) {
      map['cw'] = Variable<String>(cw.value);
    }
    if (visibility.present) {
      map['visibility'] = Variable<String>(visibility.value);
    }
    if (localOnly.present) {
      map['local_only'] = Variable<bool>(localOnly.value);
    }
    if (replyId.present) {
      map['reply_id'] = Variable<String>(replyId.value);
    }
    if (renoteId.present) {
      map['renote_id'] = Variable<String>(renoteId.value);
    }
    if (sourceNoteUri.present) {
      map['source_note_uri'] = Variable<String>(sourceNoteUri.value);
    }
    if (sourceHost.present) {
      map['source_host'] = Variable<String>(sourceHost.value);
    }
    if (fileIdsJson.present) {
      map['file_ids_json'] = Variable<String>(fileIdsJson.value);
    }
    if (channelId.present) {
      map['channel_id'] = Variable<String>(channelId.value);
    }
    if (channelName.present) {
      map['channel_name'] = Variable<String>(channelName.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DraftsCompanion(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('body: $body, ')
          ..write('cw: $cw, ')
          ..write('visibility: $visibility, ')
          ..write('localOnly: $localOnly, ')
          ..write('replyId: $replyId, ')
          ..write('renoteId: $renoteId, ')
          ..write('sourceNoteUri: $sourceNoteUri, ')
          ..write('sourceHost: $sourceHost, ')
          ..write('fileIdsJson: $fileIdsJson, ')
          ..write('channelId: $channelId, ')
          ..write('channelName: $channelName, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CustomTimelinesTable extends CustomTimelines
    with TableInfo<$CustomTimelinesTable, CustomTimelineRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CustomTimelinesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _sourcesJsonMeta = const VerificationMeta(
    'sourcesJson',
  );
  @override
  late final GeneratedColumn<String> sourcesJson = GeneratedColumn<String>(
    'sources_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    sortOrder,
    sourcesJson,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'custom_timelines';
  @override
  VerificationContext validateIntegrity(
    Insertable<CustomTimelineRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('sources_json')) {
      context.handle(
        _sourcesJsonMeta,
        sourcesJson.isAcceptableOrUnknown(
          data['sources_json']!,
          _sourcesJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sourcesJsonMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CustomTimelineRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CustomTimelineRow(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}id'],
          )!,
      name:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}name'],
          )!,
      sortOrder:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}sort_order'],
          )!,
      sourcesJson:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}sources_json'],
          )!,
      createdAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}created_at'],
          )!,
      updatedAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}updated_at'],
          )!,
    );
  }

  @override
  $CustomTimelinesTable createAlias(String alias) {
    return $CustomTimelinesTable(attachedDatabase, alias);
  }
}

class CustomTimelineRow extends DataClass
    implements Insertable<CustomTimelineRow> {
  /// v4 UUID.
  final String id;
  final String name;

  /// Display order in the kind picker; lowest first.
  final int sortOrder;

  /// JSON-encoded `List<TimelineSource>`.
  final String sourcesJson;
  final DateTime createdAt;
  final DateTime updatedAt;
  const CustomTimelineRow({
    required this.id,
    required this.name,
    required this.sortOrder,
    required this.sourcesJson,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['sort_order'] = Variable<int>(sortOrder);
    map['sources_json'] = Variable<String>(sourcesJson);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CustomTimelinesCompanion toCompanion(bool nullToAbsent) {
    return CustomTimelinesCompanion(
      id: Value(id),
      name: Value(name),
      sortOrder: Value(sortOrder),
      sourcesJson: Value(sourcesJson),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory CustomTimelineRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CustomTimelineRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      sourcesJson: serializer.fromJson<String>(json['sourcesJson']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'sourcesJson': serializer.toJson<String>(sourcesJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CustomTimelineRow copyWith({
    String? id,
    String? name,
    int? sortOrder,
    String? sourcesJson,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => CustomTimelineRow(
    id: id ?? this.id,
    name: name ?? this.name,
    sortOrder: sortOrder ?? this.sortOrder,
    sourcesJson: sourcesJson ?? this.sourcesJson,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  CustomTimelineRow copyWithCompanion(CustomTimelinesCompanion data) {
    return CustomTimelineRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      sourcesJson:
          data.sourcesJson.present ? data.sourcesJson.value : this.sourcesJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CustomTimelineRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('sourcesJson: $sourcesJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, sortOrder, sourcesJson, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CustomTimelineRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.sortOrder == this.sortOrder &&
          other.sourcesJson == this.sourcesJson &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class CustomTimelinesCompanion extends UpdateCompanion<CustomTimelineRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<int> sortOrder;
  final Value<String> sourcesJson;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const CustomTimelinesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.sourcesJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CustomTimelinesCompanion.insert({
    required String id,
    required String name,
    this.sortOrder = const Value.absent(),
    required String sourcesJson,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       sourcesJson = Value(sourcesJson),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<CustomTimelineRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<int>? sortOrder,
    Expression<String>? sourcesJson,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (sourcesJson != null) 'sources_json': sourcesJson,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CustomTimelinesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<int>? sortOrder,
    Value<String>? sourcesJson,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return CustomTimelinesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      sortOrder: sortOrder ?? this.sortOrder,
      sourcesJson: sourcesJson ?? this.sourcesJson,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (sourcesJson.present) {
      map['sources_json'] = Variable<String>(sourcesJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CustomTimelinesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('sourcesJson: $sourcesJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AppPreferencesTable extends AppPreferences
    with TableInfo<$AppPreferencesTable, AppPreferenceRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppPreferencesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('singleton'),
  );
  static const VerificationMeta _themeModeMeta = const VerificationMeta(
    'themeMode',
  );
  @override
  late final GeneratedColumn<String> themeMode = GeneratedColumn<String>(
    'theme_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('system'),
  );
  static const VerificationMeta _textScaleMeta = const VerificationMeta(
    'textScale',
  );
  @override
  late final GeneratedColumn<double> textScale = GeneratedColumn<double>(
    'text_scale',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(1.0),
  );
  static const VerificationMeta _disableAnimatedMfmMeta =
      const VerificationMeta('disableAnimatedMfm');
  @override
  late final GeneratedColumn<bool> disableAnimatedMfm = GeneratedColumn<bool>(
    'disable_animated_mfm',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("disable_animated_mfm" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _reducedMotionOverrideMeta =
      const VerificationMeta('reducedMotionOverride');
  @override
  late final GeneratedColumn<String> reducedMotionOverride =
      GeneratedColumn<String>(
        'reduced_motion_override',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant(''),
      );
  static const VerificationMeta _blurSensitiveChannelsMeta =
      const VerificationMeta('blurSensitiveChannels');
  @override
  late final GeneratedColumn<bool> blurSensitiveChannels =
      GeneratedColumn<bool>(
        'blur_sensitive_channels',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("blur_sensitive_channels" IN (0, 1))',
        ),
        defaultValue: const Constant(true),
      );
  static const VerificationMeta _automaticUpdateChecksMeta =
      const VerificationMeta('automaticUpdateChecks');
  @override
  late final GeneratedColumn<bool> automaticUpdateChecks =
      GeneratedColumn<bool>(
        'automatic_update_checks',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("automatic_update_checks" IN (0, 1))',
        ),
        defaultValue: const Constant(true),
      );
  static const VerificationMeta _lastUpdateCheckAtMeta = const VerificationMeta(
    'lastUpdateCheckAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastUpdateCheckAt =
      GeneratedColumn<DateTime>(
        'last_update_check_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _dismissedUpdateVersionCodeMeta =
      const VerificationMeta('dismissedUpdateVersionCode');
  @override
  late final GeneratedColumn<int> dismissedUpdateVersionCode =
      GeneratedColumn<int>(
        'dismissed_update_version_code',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    themeMode,
    textScale,
    disableAnimatedMfm,
    reducedMotionOverride,
    blurSensitiveChannels,
    automaticUpdateChecks,
    lastUpdateCheckAt,
    dismissedUpdateVersionCode,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_preferences';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppPreferenceRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('theme_mode')) {
      context.handle(
        _themeModeMeta,
        themeMode.isAcceptableOrUnknown(data['theme_mode']!, _themeModeMeta),
      );
    }
    if (data.containsKey('text_scale')) {
      context.handle(
        _textScaleMeta,
        textScale.isAcceptableOrUnknown(data['text_scale']!, _textScaleMeta),
      );
    }
    if (data.containsKey('disable_animated_mfm')) {
      context.handle(
        _disableAnimatedMfmMeta,
        disableAnimatedMfm.isAcceptableOrUnknown(
          data['disable_animated_mfm']!,
          _disableAnimatedMfmMeta,
        ),
      );
    }
    if (data.containsKey('reduced_motion_override')) {
      context.handle(
        _reducedMotionOverrideMeta,
        reducedMotionOverride.isAcceptableOrUnknown(
          data['reduced_motion_override']!,
          _reducedMotionOverrideMeta,
        ),
      );
    }
    if (data.containsKey('blur_sensitive_channels')) {
      context.handle(
        _blurSensitiveChannelsMeta,
        blurSensitiveChannels.isAcceptableOrUnknown(
          data['blur_sensitive_channels']!,
          _blurSensitiveChannelsMeta,
        ),
      );
    }
    if (data.containsKey('automatic_update_checks')) {
      context.handle(
        _automaticUpdateChecksMeta,
        automaticUpdateChecks.isAcceptableOrUnknown(
          data['automatic_update_checks']!,
          _automaticUpdateChecksMeta,
        ),
      );
    }
    if (data.containsKey('last_update_check_at')) {
      context.handle(
        _lastUpdateCheckAtMeta,
        lastUpdateCheckAt.isAcceptableOrUnknown(
          data['last_update_check_at']!,
          _lastUpdateCheckAtMeta,
        ),
      );
    }
    if (data.containsKey('dismissed_update_version_code')) {
      context.handle(
        _dismissedUpdateVersionCodeMeta,
        dismissedUpdateVersionCode.isAcceptableOrUnknown(
          data['dismissed_update_version_code']!,
          _dismissedUpdateVersionCodeMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AppPreferenceRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppPreferenceRow(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}id'],
          )!,
      themeMode:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}theme_mode'],
          )!,
      textScale:
          attachedDatabase.typeMapping.read(
            DriftSqlType.double,
            data['${effectivePrefix}text_scale'],
          )!,
      disableAnimatedMfm:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}disable_animated_mfm'],
          )!,
      reducedMotionOverride:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}reduced_motion_override'],
          )!,
      blurSensitiveChannels:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}blur_sensitive_channels'],
          )!,
      automaticUpdateChecks:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}automatic_update_checks'],
          )!,
      lastUpdateCheckAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_update_check_at'],
      ),
      dismissedUpdateVersionCode: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}dismissed_update_version_code'],
      ),
      updatedAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}updated_at'],
          )!,
    );
  }

  @override
  $AppPreferencesTable createAlias(String alias) {
    return $AppPreferencesTable(attachedDatabase, alias);
  }
}

class AppPreferenceRow extends DataClass
    implements Insertable<AppPreferenceRow> {
  /// Always the literal `'singleton'`. The PK exists only so we can
  /// `insertOrReplace` to update.
  final String id;

  /// `system` / `light` / `dark`.
  final String themeMode;

  /// 1.0 = no override; otherwise multiplied with MediaQuery's text
  /// scaler to produce the effective scale.
  final double textScale;
  final bool disableAnimatedMfm;

  /// `null` (inherit OS) is encoded as the empty string here so we
  /// can avoid making the column nullable + still distinguish unset.
  ///   '' = inherit, 'on' = force motion on, 'off' = force motion off.
  final String reducedMotionOverride;

  /// When true, blur the body / media / quote of notes posted in a
  /// channel flagged `isSensitive`. Default-on so a new install errs
  /// on the safe side; users can turn it off in Settings.
  final bool blurSensitiveChannels;

  /// Only the independent GitHub updater reads these preferences.
  final bool automaticUpdateChecks;
  final DateTime? lastUpdateCheckAt;
  final int? dismissedUpdateVersionCode;
  final DateTime updatedAt;
  const AppPreferenceRow({
    required this.id,
    required this.themeMode,
    required this.textScale,
    required this.disableAnimatedMfm,
    required this.reducedMotionOverride,
    required this.blurSensitiveChannels,
    required this.automaticUpdateChecks,
    this.lastUpdateCheckAt,
    this.dismissedUpdateVersionCode,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['theme_mode'] = Variable<String>(themeMode);
    map['text_scale'] = Variable<double>(textScale);
    map['disable_animated_mfm'] = Variable<bool>(disableAnimatedMfm);
    map['reduced_motion_override'] = Variable<String>(reducedMotionOverride);
    map['blur_sensitive_channels'] = Variable<bool>(blurSensitiveChannels);
    map['automatic_update_checks'] = Variable<bool>(automaticUpdateChecks);
    if (!nullToAbsent || lastUpdateCheckAt != null) {
      map['last_update_check_at'] = Variable<DateTime>(lastUpdateCheckAt);
    }
    if (!nullToAbsent || dismissedUpdateVersionCode != null) {
      map['dismissed_update_version_code'] = Variable<int>(
        dismissedUpdateVersionCode,
      );
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  AppPreferencesCompanion toCompanion(bool nullToAbsent) {
    return AppPreferencesCompanion(
      id: Value(id),
      themeMode: Value(themeMode),
      textScale: Value(textScale),
      disableAnimatedMfm: Value(disableAnimatedMfm),
      reducedMotionOverride: Value(reducedMotionOverride),
      blurSensitiveChannels: Value(blurSensitiveChannels),
      automaticUpdateChecks: Value(automaticUpdateChecks),
      lastUpdateCheckAt:
          lastUpdateCheckAt == null && nullToAbsent
              ? const Value.absent()
              : Value(lastUpdateCheckAt),
      dismissedUpdateVersionCode:
          dismissedUpdateVersionCode == null && nullToAbsent
              ? const Value.absent()
              : Value(dismissedUpdateVersionCode),
      updatedAt: Value(updatedAt),
    );
  }

  factory AppPreferenceRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppPreferenceRow(
      id: serializer.fromJson<String>(json['id']),
      themeMode: serializer.fromJson<String>(json['themeMode']),
      textScale: serializer.fromJson<double>(json['textScale']),
      disableAnimatedMfm: serializer.fromJson<bool>(json['disableAnimatedMfm']),
      reducedMotionOverride: serializer.fromJson<String>(
        json['reducedMotionOverride'],
      ),
      blurSensitiveChannels: serializer.fromJson<bool>(
        json['blurSensitiveChannels'],
      ),
      automaticUpdateChecks: serializer.fromJson<bool>(
        json['automaticUpdateChecks'],
      ),
      lastUpdateCheckAt: serializer.fromJson<DateTime?>(
        json['lastUpdateCheckAt'],
      ),
      dismissedUpdateVersionCode: serializer.fromJson<int?>(
        json['dismissedUpdateVersionCode'],
      ),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'themeMode': serializer.toJson<String>(themeMode),
      'textScale': serializer.toJson<double>(textScale),
      'disableAnimatedMfm': serializer.toJson<bool>(disableAnimatedMfm),
      'reducedMotionOverride': serializer.toJson<String>(reducedMotionOverride),
      'blurSensitiveChannels': serializer.toJson<bool>(blurSensitiveChannels),
      'automaticUpdateChecks': serializer.toJson<bool>(automaticUpdateChecks),
      'lastUpdateCheckAt': serializer.toJson<DateTime?>(lastUpdateCheckAt),
      'dismissedUpdateVersionCode': serializer.toJson<int?>(
        dismissedUpdateVersionCode,
      ),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  AppPreferenceRow copyWith({
    String? id,
    String? themeMode,
    double? textScale,
    bool? disableAnimatedMfm,
    String? reducedMotionOverride,
    bool? blurSensitiveChannels,
    bool? automaticUpdateChecks,
    Value<DateTime?> lastUpdateCheckAt = const Value.absent(),
    Value<int?> dismissedUpdateVersionCode = const Value.absent(),
    DateTime? updatedAt,
  }) => AppPreferenceRow(
    id: id ?? this.id,
    themeMode: themeMode ?? this.themeMode,
    textScale: textScale ?? this.textScale,
    disableAnimatedMfm: disableAnimatedMfm ?? this.disableAnimatedMfm,
    reducedMotionOverride: reducedMotionOverride ?? this.reducedMotionOverride,
    blurSensitiveChannels: blurSensitiveChannels ?? this.blurSensitiveChannels,
    automaticUpdateChecks: automaticUpdateChecks ?? this.automaticUpdateChecks,
    lastUpdateCheckAt:
        lastUpdateCheckAt.present
            ? lastUpdateCheckAt.value
            : this.lastUpdateCheckAt,
    dismissedUpdateVersionCode:
        dismissedUpdateVersionCode.present
            ? dismissedUpdateVersionCode.value
            : this.dismissedUpdateVersionCode,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  AppPreferenceRow copyWithCompanion(AppPreferencesCompanion data) {
    return AppPreferenceRow(
      id: data.id.present ? data.id.value : this.id,
      themeMode: data.themeMode.present ? data.themeMode.value : this.themeMode,
      textScale: data.textScale.present ? data.textScale.value : this.textScale,
      disableAnimatedMfm:
          data.disableAnimatedMfm.present
              ? data.disableAnimatedMfm.value
              : this.disableAnimatedMfm,
      reducedMotionOverride:
          data.reducedMotionOverride.present
              ? data.reducedMotionOverride.value
              : this.reducedMotionOverride,
      blurSensitiveChannels:
          data.blurSensitiveChannels.present
              ? data.blurSensitiveChannels.value
              : this.blurSensitiveChannels,
      automaticUpdateChecks:
          data.automaticUpdateChecks.present
              ? data.automaticUpdateChecks.value
              : this.automaticUpdateChecks,
      lastUpdateCheckAt:
          data.lastUpdateCheckAt.present
              ? data.lastUpdateCheckAt.value
              : this.lastUpdateCheckAt,
      dismissedUpdateVersionCode:
          data.dismissedUpdateVersionCode.present
              ? data.dismissedUpdateVersionCode.value
              : this.dismissedUpdateVersionCode,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppPreferenceRow(')
          ..write('id: $id, ')
          ..write('themeMode: $themeMode, ')
          ..write('textScale: $textScale, ')
          ..write('disableAnimatedMfm: $disableAnimatedMfm, ')
          ..write('reducedMotionOverride: $reducedMotionOverride, ')
          ..write('blurSensitiveChannels: $blurSensitiveChannels, ')
          ..write('automaticUpdateChecks: $automaticUpdateChecks, ')
          ..write('lastUpdateCheckAt: $lastUpdateCheckAt, ')
          ..write('dismissedUpdateVersionCode: $dismissedUpdateVersionCode, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    themeMode,
    textScale,
    disableAnimatedMfm,
    reducedMotionOverride,
    blurSensitiveChannels,
    automaticUpdateChecks,
    lastUpdateCheckAt,
    dismissedUpdateVersionCode,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppPreferenceRow &&
          other.id == this.id &&
          other.themeMode == this.themeMode &&
          other.textScale == this.textScale &&
          other.disableAnimatedMfm == this.disableAnimatedMfm &&
          other.reducedMotionOverride == this.reducedMotionOverride &&
          other.blurSensitiveChannels == this.blurSensitiveChannels &&
          other.automaticUpdateChecks == this.automaticUpdateChecks &&
          other.lastUpdateCheckAt == this.lastUpdateCheckAt &&
          other.dismissedUpdateVersionCode == this.dismissedUpdateVersionCode &&
          other.updatedAt == this.updatedAt);
}

class AppPreferencesCompanion extends UpdateCompanion<AppPreferenceRow> {
  final Value<String> id;
  final Value<String> themeMode;
  final Value<double> textScale;
  final Value<bool> disableAnimatedMfm;
  final Value<String> reducedMotionOverride;
  final Value<bool> blurSensitiveChannels;
  final Value<bool> automaticUpdateChecks;
  final Value<DateTime?> lastUpdateCheckAt;
  final Value<int?> dismissedUpdateVersionCode;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const AppPreferencesCompanion({
    this.id = const Value.absent(),
    this.themeMode = const Value.absent(),
    this.textScale = const Value.absent(),
    this.disableAnimatedMfm = const Value.absent(),
    this.reducedMotionOverride = const Value.absent(),
    this.blurSensitiveChannels = const Value.absent(),
    this.automaticUpdateChecks = const Value.absent(),
    this.lastUpdateCheckAt = const Value.absent(),
    this.dismissedUpdateVersionCode = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppPreferencesCompanion.insert({
    this.id = const Value.absent(),
    this.themeMode = const Value.absent(),
    this.textScale = const Value.absent(),
    this.disableAnimatedMfm = const Value.absent(),
    this.reducedMotionOverride = const Value.absent(),
    this.blurSensitiveChannels = const Value.absent(),
    this.automaticUpdateChecks = const Value.absent(),
    this.lastUpdateCheckAt = const Value.absent(),
    this.dismissedUpdateVersionCode = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : updatedAt = Value(updatedAt);
  static Insertable<AppPreferenceRow> custom({
    Expression<String>? id,
    Expression<String>? themeMode,
    Expression<double>? textScale,
    Expression<bool>? disableAnimatedMfm,
    Expression<String>? reducedMotionOverride,
    Expression<bool>? blurSensitiveChannels,
    Expression<bool>? automaticUpdateChecks,
    Expression<DateTime>? lastUpdateCheckAt,
    Expression<int>? dismissedUpdateVersionCode,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (themeMode != null) 'theme_mode': themeMode,
      if (textScale != null) 'text_scale': textScale,
      if (disableAnimatedMfm != null)
        'disable_animated_mfm': disableAnimatedMfm,
      if (reducedMotionOverride != null)
        'reduced_motion_override': reducedMotionOverride,
      if (blurSensitiveChannels != null)
        'blur_sensitive_channels': blurSensitiveChannels,
      if (automaticUpdateChecks != null)
        'automatic_update_checks': automaticUpdateChecks,
      if (lastUpdateCheckAt != null) 'last_update_check_at': lastUpdateCheckAt,
      if (dismissedUpdateVersionCode != null)
        'dismissed_update_version_code': dismissedUpdateVersionCode,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppPreferencesCompanion copyWith({
    Value<String>? id,
    Value<String>? themeMode,
    Value<double>? textScale,
    Value<bool>? disableAnimatedMfm,
    Value<String>? reducedMotionOverride,
    Value<bool>? blurSensitiveChannels,
    Value<bool>? automaticUpdateChecks,
    Value<DateTime?>? lastUpdateCheckAt,
    Value<int?>? dismissedUpdateVersionCode,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return AppPreferencesCompanion(
      id: id ?? this.id,
      themeMode: themeMode ?? this.themeMode,
      textScale: textScale ?? this.textScale,
      disableAnimatedMfm: disableAnimatedMfm ?? this.disableAnimatedMfm,
      reducedMotionOverride:
          reducedMotionOverride ?? this.reducedMotionOverride,
      blurSensitiveChannels:
          blurSensitiveChannels ?? this.blurSensitiveChannels,
      automaticUpdateChecks:
          automaticUpdateChecks ?? this.automaticUpdateChecks,
      lastUpdateCheckAt: lastUpdateCheckAt ?? this.lastUpdateCheckAt,
      dismissedUpdateVersionCode:
          dismissedUpdateVersionCode ?? this.dismissedUpdateVersionCode,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (themeMode.present) {
      map['theme_mode'] = Variable<String>(themeMode.value);
    }
    if (textScale.present) {
      map['text_scale'] = Variable<double>(textScale.value);
    }
    if (disableAnimatedMfm.present) {
      map['disable_animated_mfm'] = Variable<bool>(disableAnimatedMfm.value);
    }
    if (reducedMotionOverride.present) {
      map['reduced_motion_override'] = Variable<String>(
        reducedMotionOverride.value,
      );
    }
    if (blurSensitiveChannels.present) {
      map['blur_sensitive_channels'] = Variable<bool>(
        blurSensitiveChannels.value,
      );
    }
    if (automaticUpdateChecks.present) {
      map['automatic_update_checks'] = Variable<bool>(
        automaticUpdateChecks.value,
      );
    }
    if (lastUpdateCheckAt.present) {
      map['last_update_check_at'] = Variable<DateTime>(lastUpdateCheckAt.value);
    }
    if (dismissedUpdateVersionCode.present) {
      map['dismissed_update_version_code'] = Variable<int>(
        dismissedUpdateVersionCode.value,
      );
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppPreferencesCompanion(')
          ..write('id: $id, ')
          ..write('themeMode: $themeMode, ')
          ..write('textScale: $textScale, ')
          ..write('disableAnimatedMfm: $disableAnimatedMfm, ')
          ..write('reducedMotionOverride: $reducedMotionOverride, ')
          ..write('blurSensitiveChannels: $blurSensitiveChannels, ')
          ..write('automaticUpdateChecks: $automaticUpdateChecks, ')
          ..write('lastUpdateCheckAt: $lastUpdateCheckAt, ')
          ..write('dismissedUpdateVersionCode: $dismissedUpdateVersionCode, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ServersTable servers = $ServersTable(this);
  late final $AccountsTable accounts = $AccountsTable(this);
  late final $UsersTable users = $UsersTable(this);
  late final $NotesTable notes = $NotesTable(this);
  late final $EmojisTable emojis = $EmojisTable(this);
  late final $EmojiCatalogsTable emojiCatalogs = $EmojiCatalogsTable(this);
  late final $TimelineItemsTable timelineItems = $TimelineItemsTable(this);
  late final $HeightCacheTable heightCache = $HeightCacheTable(this);
  late final $ReactionRecentsTable reactionRecents = $ReactionRecentsTable(
    this,
  );
  late final $DraftsTable drafts = $DraftsTable(this);
  late final $CustomTimelinesTable customTimelines = $CustomTimelinesTable(
    this,
  );
  late final $AppPreferencesTable appPreferences = $AppPreferencesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    servers,
    accounts,
    users,
    notes,
    emojis,
    emojiCatalogs,
    timelineItems,
    heightCache,
    reactionRecents,
    drafts,
    customTimelines,
    appPreferences,
  ];
}

typedef $$ServersTableCreateCompanionBuilder =
    ServersCompanion Function({
      required String host,
      Value<String?> name,
      Value<String?> description,
      Value<String?> softwareName,
      Value<String?> softwareVersion,
      Value<String?> iconUrl,
      Value<String?> bannerUrl,
      Value<DateTime?> metaFetchedAt,
      Value<String?> rawJson,
      Value<int> rowid,
    });
typedef $$ServersTableUpdateCompanionBuilder =
    ServersCompanion Function({
      Value<String> host,
      Value<String?> name,
      Value<String?> description,
      Value<String?> softwareName,
      Value<String?> softwareVersion,
      Value<String?> iconUrl,
      Value<String?> bannerUrl,
      Value<DateTime?> metaFetchedAt,
      Value<String?> rawJson,
      Value<int> rowid,
    });

class $$ServersTableFilterComposer
    extends Composer<_$AppDatabase, $ServersTable> {
  $$ServersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get host => $composableBuilder(
    column: $table.host,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get softwareName => $composableBuilder(
    column: $table.softwareName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get softwareVersion => $composableBuilder(
    column: $table.softwareVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get iconUrl => $composableBuilder(
    column: $table.iconUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bannerUrl => $composableBuilder(
    column: $table.bannerUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get metaFetchedAt => $composableBuilder(
    column: $table.metaFetchedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rawJson => $composableBuilder(
    column: $table.rawJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ServersTableOrderingComposer
    extends Composer<_$AppDatabase, $ServersTable> {
  $$ServersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get host => $composableBuilder(
    column: $table.host,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get softwareName => $composableBuilder(
    column: $table.softwareName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get softwareVersion => $composableBuilder(
    column: $table.softwareVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get iconUrl => $composableBuilder(
    column: $table.iconUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bannerUrl => $composableBuilder(
    column: $table.bannerUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get metaFetchedAt => $composableBuilder(
    column: $table.metaFetchedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rawJson => $composableBuilder(
    column: $table.rawJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ServersTableAnnotationComposer
    extends Composer<_$AppDatabase, $ServersTable> {
  $$ServersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get host =>
      $composableBuilder(column: $table.host, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get softwareName => $composableBuilder(
    column: $table.softwareName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get softwareVersion => $composableBuilder(
    column: $table.softwareVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get iconUrl =>
      $composableBuilder(column: $table.iconUrl, builder: (column) => column);

  GeneratedColumn<String> get bannerUrl =>
      $composableBuilder(column: $table.bannerUrl, builder: (column) => column);

  GeneratedColumn<DateTime> get metaFetchedAt => $composableBuilder(
    column: $table.metaFetchedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rawJson =>
      $composableBuilder(column: $table.rawJson, builder: (column) => column);
}

class $$ServersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ServersTable,
          ServerRow,
          $$ServersTableFilterComposer,
          $$ServersTableOrderingComposer,
          $$ServersTableAnnotationComposer,
          $$ServersTableCreateCompanionBuilder,
          $$ServersTableUpdateCompanionBuilder,
          (ServerRow, BaseReferences<_$AppDatabase, $ServersTable, ServerRow>),
          ServerRow,
          PrefetchHooks Function()
        > {
  $$ServersTableTableManager(_$AppDatabase db, $ServersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$ServersTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$ServersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$ServersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> host = const Value.absent(),
                Value<String?> name = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> softwareName = const Value.absent(),
                Value<String?> softwareVersion = const Value.absent(),
                Value<String?> iconUrl = const Value.absent(),
                Value<String?> bannerUrl = const Value.absent(),
                Value<DateTime?> metaFetchedAt = const Value.absent(),
                Value<String?> rawJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ServersCompanion(
                host: host,
                name: name,
                description: description,
                softwareName: softwareName,
                softwareVersion: softwareVersion,
                iconUrl: iconUrl,
                bannerUrl: bannerUrl,
                metaFetchedAt: metaFetchedAt,
                rawJson: rawJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String host,
                Value<String?> name = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> softwareName = const Value.absent(),
                Value<String?> softwareVersion = const Value.absent(),
                Value<String?> iconUrl = const Value.absent(),
                Value<String?> bannerUrl = const Value.absent(),
                Value<DateTime?> metaFetchedAt = const Value.absent(),
                Value<String?> rawJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ServersCompanion.insert(
                host: host,
                name: name,
                description: description,
                softwareName: softwareName,
                softwareVersion: softwareVersion,
                iconUrl: iconUrl,
                bannerUrl: bannerUrl,
                metaFetchedAt: metaFetchedAt,
                rawJson: rawJson,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ServersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ServersTable,
      ServerRow,
      $$ServersTableFilterComposer,
      $$ServersTableOrderingComposer,
      $$ServersTableAnnotationComposer,
      $$ServersTableCreateCompanionBuilder,
      $$ServersTableUpdateCompanionBuilder,
      (ServerRow, BaseReferences<_$AppDatabase, $ServersTable, ServerRow>),
      ServerRow,
      PrefetchHooks Function()
    >;
typedef $$AccountsTableCreateCompanionBuilder =
    AccountsCompanion Function({
      required String id,
      required String host,
      required String userId,
      required String username,
      Value<String?> displayName,
      Value<String?> avatarUrl,
      Value<bool> isCat,
      Value<bool> isAdmin,
      required DateTime addedAt,
      Value<DateTime?> lastUsedAt,
      Value<int> rowid,
    });
typedef $$AccountsTableUpdateCompanionBuilder =
    AccountsCompanion Function({
      Value<String> id,
      Value<String> host,
      Value<String> userId,
      Value<String> username,
      Value<String?> displayName,
      Value<String?> avatarUrl,
      Value<bool> isCat,
      Value<bool> isAdmin,
      Value<DateTime> addedAt,
      Value<DateTime?> lastUsedAt,
      Value<int> rowid,
    });

class $$AccountsTableFilterComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get host => $composableBuilder(
    column: $table.host,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get username => $composableBuilder(
    column: $table.username,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get avatarUrl => $composableBuilder(
    column: $table.avatarUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCat => $composableBuilder(
    column: $table.isCat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isAdmin => $composableBuilder(
    column: $table.isAdmin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastUsedAt => $composableBuilder(
    column: $table.lastUsedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AccountsTableOrderingComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get host => $composableBuilder(
    column: $table.host,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get username => $composableBuilder(
    column: $table.username,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get avatarUrl => $composableBuilder(
    column: $table.avatarUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCat => $composableBuilder(
    column: $table.isCat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isAdmin => $composableBuilder(
    column: $table.isAdmin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastUsedAt => $composableBuilder(
    column: $table.lastUsedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AccountsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get host =>
      $composableBuilder(column: $table.host, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get username =>
      $composableBuilder(column: $table.username, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get avatarUrl =>
      $composableBuilder(column: $table.avatarUrl, builder: (column) => column);

  GeneratedColumn<bool> get isCat =>
      $composableBuilder(column: $table.isCat, builder: (column) => column);

  GeneratedColumn<bool> get isAdmin =>
      $composableBuilder(column: $table.isAdmin, builder: (column) => column);

  GeneratedColumn<DateTime> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastUsedAt => $composableBuilder(
    column: $table.lastUsedAt,
    builder: (column) => column,
  );
}

class $$AccountsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AccountsTable,
          AccountRow,
          $$AccountsTableFilterComposer,
          $$AccountsTableOrderingComposer,
          $$AccountsTableAnnotationComposer,
          $$AccountsTableCreateCompanionBuilder,
          $$AccountsTableUpdateCompanionBuilder,
          (
            AccountRow,
            BaseReferences<_$AppDatabase, $AccountsTable, AccountRow>,
          ),
          AccountRow,
          PrefetchHooks Function()
        > {
  $$AccountsTableTableManager(_$AppDatabase db, $AccountsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$AccountsTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$AccountsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$AccountsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> host = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> username = const Value.absent(),
                Value<String?> displayName = const Value.absent(),
                Value<String?> avatarUrl = const Value.absent(),
                Value<bool> isCat = const Value.absent(),
                Value<bool> isAdmin = const Value.absent(),
                Value<DateTime> addedAt = const Value.absent(),
                Value<DateTime?> lastUsedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AccountsCompanion(
                id: id,
                host: host,
                userId: userId,
                username: username,
                displayName: displayName,
                avatarUrl: avatarUrl,
                isCat: isCat,
                isAdmin: isAdmin,
                addedAt: addedAt,
                lastUsedAt: lastUsedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String host,
                required String userId,
                required String username,
                Value<String?> displayName = const Value.absent(),
                Value<String?> avatarUrl = const Value.absent(),
                Value<bool> isCat = const Value.absent(),
                Value<bool> isAdmin = const Value.absent(),
                required DateTime addedAt,
                Value<DateTime?> lastUsedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AccountsCompanion.insert(
                id: id,
                host: host,
                userId: userId,
                username: username,
                displayName: displayName,
                avatarUrl: avatarUrl,
                isCat: isCat,
                isAdmin: isAdmin,
                addedAt: addedAt,
                lastUsedAt: lastUsedAt,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AccountsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AccountsTable,
      AccountRow,
      $$AccountsTableFilterComposer,
      $$AccountsTableOrderingComposer,
      $$AccountsTableAnnotationComposer,
      $$AccountsTableCreateCompanionBuilder,
      $$AccountsTableUpdateCompanionBuilder,
      (AccountRow, BaseReferences<_$AppDatabase, $AccountsTable, AccountRow>),
      AccountRow,
      PrefetchHooks Function()
    >;
typedef $$UsersTableCreateCompanionBuilder =
    UsersCompanion Function({
      required String viewerHost,
      required String id,
      required String username,
      Value<String?> host,
      Value<String?> name,
      Value<String?> avatarUrl,
      Value<String?> avatarBlurhash,
      Value<bool> isBot,
      Value<bool> isCat,
      required DateTime fetchedAt,
      Value<String?> rawJson,
      Value<int> rowid,
    });
typedef $$UsersTableUpdateCompanionBuilder =
    UsersCompanion Function({
      Value<String> viewerHost,
      Value<String> id,
      Value<String> username,
      Value<String?> host,
      Value<String?> name,
      Value<String?> avatarUrl,
      Value<String?> avatarBlurhash,
      Value<bool> isBot,
      Value<bool> isCat,
      Value<DateTime> fetchedAt,
      Value<String?> rawJson,
      Value<int> rowid,
    });

class $$UsersTableFilterComposer extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get viewerHost => $composableBuilder(
    column: $table.viewerHost,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get username => $composableBuilder(
    column: $table.username,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get host => $composableBuilder(
    column: $table.host,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get avatarUrl => $composableBuilder(
    column: $table.avatarUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get avatarBlurhash => $composableBuilder(
    column: $table.avatarBlurhash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isBot => $composableBuilder(
    column: $table.isBot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCat => $composableBuilder(
    column: $table.isCat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rawJson => $composableBuilder(
    column: $table.rawJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UsersTableOrderingComposer
    extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get viewerHost => $composableBuilder(
    column: $table.viewerHost,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get username => $composableBuilder(
    column: $table.username,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get host => $composableBuilder(
    column: $table.host,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get avatarUrl => $composableBuilder(
    column: $table.avatarUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get avatarBlurhash => $composableBuilder(
    column: $table.avatarBlurhash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isBot => $composableBuilder(
    column: $table.isBot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCat => $composableBuilder(
    column: $table.isCat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rawJson => $composableBuilder(
    column: $table.rawJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UsersTableAnnotationComposer
    extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get viewerHost => $composableBuilder(
    column: $table.viewerHost,
    builder: (column) => column,
  );

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get username =>
      $composableBuilder(column: $table.username, builder: (column) => column);

  GeneratedColumn<String> get host =>
      $composableBuilder(column: $table.host, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get avatarUrl =>
      $composableBuilder(column: $table.avatarUrl, builder: (column) => column);

  GeneratedColumn<String> get avatarBlurhash => $composableBuilder(
    column: $table.avatarBlurhash,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isBot =>
      $composableBuilder(column: $table.isBot, builder: (column) => column);

  GeneratedColumn<bool> get isCat =>
      $composableBuilder(column: $table.isCat, builder: (column) => column);

  GeneratedColumn<DateTime> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);

  GeneratedColumn<String> get rawJson =>
      $composableBuilder(column: $table.rawJson, builder: (column) => column);
}

class $$UsersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UsersTable,
          UserRow,
          $$UsersTableFilterComposer,
          $$UsersTableOrderingComposer,
          $$UsersTableAnnotationComposer,
          $$UsersTableCreateCompanionBuilder,
          $$UsersTableUpdateCompanionBuilder,
          (UserRow, BaseReferences<_$AppDatabase, $UsersTable, UserRow>),
          UserRow,
          PrefetchHooks Function()
        > {
  $$UsersTableTableManager(_$AppDatabase db, $UsersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$UsersTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$UsersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$UsersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> viewerHost = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String> username = const Value.absent(),
                Value<String?> host = const Value.absent(),
                Value<String?> name = const Value.absent(),
                Value<String?> avatarUrl = const Value.absent(),
                Value<String?> avatarBlurhash = const Value.absent(),
                Value<bool> isBot = const Value.absent(),
                Value<bool> isCat = const Value.absent(),
                Value<DateTime> fetchedAt = const Value.absent(),
                Value<String?> rawJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UsersCompanion(
                viewerHost: viewerHost,
                id: id,
                username: username,
                host: host,
                name: name,
                avatarUrl: avatarUrl,
                avatarBlurhash: avatarBlurhash,
                isBot: isBot,
                isCat: isCat,
                fetchedAt: fetchedAt,
                rawJson: rawJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String viewerHost,
                required String id,
                required String username,
                Value<String?> host = const Value.absent(),
                Value<String?> name = const Value.absent(),
                Value<String?> avatarUrl = const Value.absent(),
                Value<String?> avatarBlurhash = const Value.absent(),
                Value<bool> isBot = const Value.absent(),
                Value<bool> isCat = const Value.absent(),
                required DateTime fetchedAt,
                Value<String?> rawJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UsersCompanion.insert(
                viewerHost: viewerHost,
                id: id,
                username: username,
                host: host,
                name: name,
                avatarUrl: avatarUrl,
                avatarBlurhash: avatarBlurhash,
                isBot: isBot,
                isCat: isCat,
                fetchedAt: fetchedAt,
                rawJson: rawJson,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UsersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UsersTable,
      UserRow,
      $$UsersTableFilterComposer,
      $$UsersTableOrderingComposer,
      $$UsersTableAnnotationComposer,
      $$UsersTableCreateCompanionBuilder,
      $$UsersTableUpdateCompanionBuilder,
      (UserRow, BaseReferences<_$AppDatabase, $UsersTable, UserRow>),
      UserRow,
      PrefetchHooks Function()
    >;
typedef $$NotesTableCreateCompanionBuilder =
    NotesCompanion Function({
      required String sourceHost,
      required String id,
      required String userViewerHost,
      required String userId,
      required DateTime createdAt,
      Value<DateTime?> updatedAt,
      Value<String?> body,
      Value<String?> cw,
      required String visibility,
      Value<String?> replyId,
      Value<String?> renoteId,
      Value<int> repliesCount,
      Value<int> renoteCount,
      Value<String?> reactionsJson,
      Value<String?> rawJson,
      Value<int> revision,
      Value<int> rowid,
    });
typedef $$NotesTableUpdateCompanionBuilder =
    NotesCompanion Function({
      Value<String> sourceHost,
      Value<String> id,
      Value<String> userViewerHost,
      Value<String> userId,
      Value<DateTime> createdAt,
      Value<DateTime?> updatedAt,
      Value<String?> body,
      Value<String?> cw,
      Value<String> visibility,
      Value<String?> replyId,
      Value<String?> renoteId,
      Value<int> repliesCount,
      Value<int> renoteCount,
      Value<String?> reactionsJson,
      Value<String?> rawJson,
      Value<int> revision,
      Value<int> rowid,
    });

class $$NotesTableFilterComposer extends Composer<_$AppDatabase, $NotesTable> {
  $$NotesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get sourceHost => $composableBuilder(
    column: $table.sourceHost,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userViewerHost => $composableBuilder(
    column: $table.userViewerHost,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cw => $composableBuilder(
    column: $table.cw,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get visibility => $composableBuilder(
    column: $table.visibility,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get replyId => $composableBuilder(
    column: $table.replyId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get renoteId => $composableBuilder(
    column: $table.renoteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get repliesCount => $composableBuilder(
    column: $table.repliesCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get renoteCount => $composableBuilder(
    column: $table.renoteCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reactionsJson => $composableBuilder(
    column: $table.reactionsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rawJson => $composableBuilder(
    column: $table.rawJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnFilters(column),
  );
}

class $$NotesTableOrderingComposer
    extends Composer<_$AppDatabase, $NotesTable> {
  $$NotesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get sourceHost => $composableBuilder(
    column: $table.sourceHost,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userViewerHost => $composableBuilder(
    column: $table.userViewerHost,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cw => $composableBuilder(
    column: $table.cw,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get visibility => $composableBuilder(
    column: $table.visibility,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get replyId => $composableBuilder(
    column: $table.replyId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get renoteId => $composableBuilder(
    column: $table.renoteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get repliesCount => $composableBuilder(
    column: $table.repliesCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get renoteCount => $composableBuilder(
    column: $table.renoteCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reactionsJson => $composableBuilder(
    column: $table.reactionsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rawJson => $composableBuilder(
    column: $table.rawJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$NotesTableAnnotationComposer
    extends Composer<_$AppDatabase, $NotesTable> {
  $$NotesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get sourceHost => $composableBuilder(
    column: $table.sourceHost,
    builder: (column) => column,
  );

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userViewerHost => $composableBuilder(
    column: $table.userViewerHost,
    builder: (column) => column,
  );

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<String> get cw =>
      $composableBuilder(column: $table.cw, builder: (column) => column);

  GeneratedColumn<String> get visibility => $composableBuilder(
    column: $table.visibility,
    builder: (column) => column,
  );

  GeneratedColumn<String> get replyId =>
      $composableBuilder(column: $table.replyId, builder: (column) => column);

  GeneratedColumn<String> get renoteId =>
      $composableBuilder(column: $table.renoteId, builder: (column) => column);

  GeneratedColumn<int> get repliesCount => $composableBuilder(
    column: $table.repliesCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get renoteCount => $composableBuilder(
    column: $table.renoteCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reactionsJson => $composableBuilder(
    column: $table.reactionsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rawJson =>
      $composableBuilder(column: $table.rawJson, builder: (column) => column);

  GeneratedColumn<int> get revision =>
      $composableBuilder(column: $table.revision, builder: (column) => column);
}

class $$NotesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $NotesTable,
          NoteRow,
          $$NotesTableFilterComposer,
          $$NotesTableOrderingComposer,
          $$NotesTableAnnotationComposer,
          $$NotesTableCreateCompanionBuilder,
          $$NotesTableUpdateCompanionBuilder,
          (NoteRow, BaseReferences<_$AppDatabase, $NotesTable, NoteRow>),
          NoteRow,
          PrefetchHooks Function()
        > {
  $$NotesTableTableManager(_$AppDatabase db, $NotesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$NotesTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$NotesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$NotesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> sourceHost = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String> userViewerHost = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<String?> body = const Value.absent(),
                Value<String?> cw = const Value.absent(),
                Value<String> visibility = const Value.absent(),
                Value<String?> replyId = const Value.absent(),
                Value<String?> renoteId = const Value.absent(),
                Value<int> repliesCount = const Value.absent(),
                Value<int> renoteCount = const Value.absent(),
                Value<String?> reactionsJson = const Value.absent(),
                Value<String?> rawJson = const Value.absent(),
                Value<int> revision = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NotesCompanion(
                sourceHost: sourceHost,
                id: id,
                userViewerHost: userViewerHost,
                userId: userId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                body: body,
                cw: cw,
                visibility: visibility,
                replyId: replyId,
                renoteId: renoteId,
                repliesCount: repliesCount,
                renoteCount: renoteCount,
                reactionsJson: reactionsJson,
                rawJson: rawJson,
                revision: revision,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String sourceHost,
                required String id,
                required String userViewerHost,
                required String userId,
                required DateTime createdAt,
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<String?> body = const Value.absent(),
                Value<String?> cw = const Value.absent(),
                required String visibility,
                Value<String?> replyId = const Value.absent(),
                Value<String?> renoteId = const Value.absent(),
                Value<int> repliesCount = const Value.absent(),
                Value<int> renoteCount = const Value.absent(),
                Value<String?> reactionsJson = const Value.absent(),
                Value<String?> rawJson = const Value.absent(),
                Value<int> revision = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NotesCompanion.insert(
                sourceHost: sourceHost,
                id: id,
                userViewerHost: userViewerHost,
                userId: userId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                body: body,
                cw: cw,
                visibility: visibility,
                replyId: replyId,
                renoteId: renoteId,
                repliesCount: repliesCount,
                renoteCount: renoteCount,
                reactionsJson: reactionsJson,
                rawJson: rawJson,
                revision: revision,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$NotesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $NotesTable,
      NoteRow,
      $$NotesTableFilterComposer,
      $$NotesTableOrderingComposer,
      $$NotesTableAnnotationComposer,
      $$NotesTableCreateCompanionBuilder,
      $$NotesTableUpdateCompanionBuilder,
      (NoteRow, BaseReferences<_$AppDatabase, $NotesTable, NoteRow>),
      NoteRow,
      PrefetchHooks Function()
    >;
typedef $$EmojisTableCreateCompanionBuilder =
    EmojisCompanion Function({
      required String host,
      required String name,
      required String url,
      Value<String?> aliasesJson,
      Value<String?> category,
      Value<bool> sensitive,
      required DateTime fetchedAt,
      Value<int> rowid,
    });
typedef $$EmojisTableUpdateCompanionBuilder =
    EmojisCompanion Function({
      Value<String> host,
      Value<String> name,
      Value<String> url,
      Value<String?> aliasesJson,
      Value<String?> category,
      Value<bool> sensitive,
      Value<DateTime> fetchedAt,
      Value<int> rowid,
    });

class $$EmojisTableFilterComposer
    extends Composer<_$AppDatabase, $EmojisTable> {
  $$EmojisTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get host => $composableBuilder(
    column: $table.host,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get aliasesJson => $composableBuilder(
    column: $table.aliasesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get sensitive => $composableBuilder(
    column: $table.sensitive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EmojisTableOrderingComposer
    extends Composer<_$AppDatabase, $EmojisTable> {
  $$EmojisTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get host => $composableBuilder(
    column: $table.host,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get aliasesJson => $composableBuilder(
    column: $table.aliasesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get sensitive => $composableBuilder(
    column: $table.sensitive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EmojisTableAnnotationComposer
    extends Composer<_$AppDatabase, $EmojisTable> {
  $$EmojisTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get host =>
      $composableBuilder(column: $table.host, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  GeneratedColumn<String> get aliasesJson => $composableBuilder(
    column: $table.aliasesJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<bool> get sensitive =>
      $composableBuilder(column: $table.sensitive, builder: (column) => column);

  GeneratedColumn<DateTime> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);
}

class $$EmojisTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EmojisTable,
          EmojiRow,
          $$EmojisTableFilterComposer,
          $$EmojisTableOrderingComposer,
          $$EmojisTableAnnotationComposer,
          $$EmojisTableCreateCompanionBuilder,
          $$EmojisTableUpdateCompanionBuilder,
          (EmojiRow, BaseReferences<_$AppDatabase, $EmojisTable, EmojiRow>),
          EmojiRow,
          PrefetchHooks Function()
        > {
  $$EmojisTableTableManager(_$AppDatabase db, $EmojisTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$EmojisTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$EmojisTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$EmojisTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> host = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> url = const Value.absent(),
                Value<String?> aliasesJson = const Value.absent(),
                Value<String?> category = const Value.absent(),
                Value<bool> sensitive = const Value.absent(),
                Value<DateTime> fetchedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EmojisCompanion(
                host: host,
                name: name,
                url: url,
                aliasesJson: aliasesJson,
                category: category,
                sensitive: sensitive,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String host,
                required String name,
                required String url,
                Value<String?> aliasesJson = const Value.absent(),
                Value<String?> category = const Value.absent(),
                Value<bool> sensitive = const Value.absent(),
                required DateTime fetchedAt,
                Value<int> rowid = const Value.absent(),
              }) => EmojisCompanion.insert(
                host: host,
                name: name,
                url: url,
                aliasesJson: aliasesJson,
                category: category,
                sensitive: sensitive,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EmojisTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EmojisTable,
      EmojiRow,
      $$EmojisTableFilterComposer,
      $$EmojisTableOrderingComposer,
      $$EmojisTableAnnotationComposer,
      $$EmojisTableCreateCompanionBuilder,
      $$EmojisTableUpdateCompanionBuilder,
      (EmojiRow, BaseReferences<_$AppDatabase, $EmojisTable, EmojiRow>),
      EmojiRow,
      PrefetchHooks Function()
    >;
typedef $$EmojiCatalogsTableCreateCompanionBuilder =
    EmojiCatalogsCompanion Function({
      required String host,
      required DateTime fetchedAt,
      Value<int> rowid,
    });
typedef $$EmojiCatalogsTableUpdateCompanionBuilder =
    EmojiCatalogsCompanion Function({
      Value<String> host,
      Value<DateTime> fetchedAt,
      Value<int> rowid,
    });

class $$EmojiCatalogsTableFilterComposer
    extends Composer<_$AppDatabase, $EmojiCatalogsTable> {
  $$EmojiCatalogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get host => $composableBuilder(
    column: $table.host,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EmojiCatalogsTableOrderingComposer
    extends Composer<_$AppDatabase, $EmojiCatalogsTable> {
  $$EmojiCatalogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get host => $composableBuilder(
    column: $table.host,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EmojiCatalogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $EmojiCatalogsTable> {
  $$EmojiCatalogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get host =>
      $composableBuilder(column: $table.host, builder: (column) => column);

  GeneratedColumn<DateTime> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);
}

class $$EmojiCatalogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EmojiCatalogsTable,
          EmojiCatalogRow,
          $$EmojiCatalogsTableFilterComposer,
          $$EmojiCatalogsTableOrderingComposer,
          $$EmojiCatalogsTableAnnotationComposer,
          $$EmojiCatalogsTableCreateCompanionBuilder,
          $$EmojiCatalogsTableUpdateCompanionBuilder,
          (
            EmojiCatalogRow,
            BaseReferences<_$AppDatabase, $EmojiCatalogsTable, EmojiCatalogRow>,
          ),
          EmojiCatalogRow,
          PrefetchHooks Function()
        > {
  $$EmojiCatalogsTableTableManager(_$AppDatabase db, $EmojiCatalogsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$EmojiCatalogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () =>
                  $$EmojiCatalogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$EmojiCatalogsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> host = const Value.absent(),
                Value<DateTime> fetchedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EmojiCatalogsCompanion(
                host: host,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String host,
                required DateTime fetchedAt,
                Value<int> rowid = const Value.absent(),
              }) => EmojiCatalogsCompanion.insert(
                host: host,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EmojiCatalogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EmojiCatalogsTable,
      EmojiCatalogRow,
      $$EmojiCatalogsTableFilterComposer,
      $$EmojiCatalogsTableOrderingComposer,
      $$EmojiCatalogsTableAnnotationComposer,
      $$EmojiCatalogsTableCreateCompanionBuilder,
      $$EmojiCatalogsTableUpdateCompanionBuilder,
      (
        EmojiCatalogRow,
        BaseReferences<_$AppDatabase, $EmojiCatalogsTable, EmojiCatalogRow>,
      ),
      EmojiCatalogRow,
      PrefetchHooks Function()
    >;
typedef $$TimelineItemsTableCreateCompanionBuilder =
    TimelineItemsCompanion Function({
      required String accountId,
      required String timelineKey,
      required String noteSourceHost,
      required String noteId,
      required DateTime createdAt,
      required DateTime receivedAt,
      Value<int> rowid,
    });
typedef $$TimelineItemsTableUpdateCompanionBuilder =
    TimelineItemsCompanion Function({
      Value<String> accountId,
      Value<String> timelineKey,
      Value<String> noteSourceHost,
      Value<String> noteId,
      Value<DateTime> createdAt,
      Value<DateTime> receivedAt,
      Value<int> rowid,
    });

class $$TimelineItemsTableFilterComposer
    extends Composer<_$AppDatabase, $TimelineItemsTable> {
  $$TimelineItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get timelineKey => $composableBuilder(
    column: $table.timelineKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get noteSourceHost => $composableBuilder(
    column: $table.noteSourceHost,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get noteId => $composableBuilder(
    column: $table.noteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get receivedAt => $composableBuilder(
    column: $table.receivedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TimelineItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $TimelineItemsTable> {
  $$TimelineItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get timelineKey => $composableBuilder(
    column: $table.timelineKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get noteSourceHost => $composableBuilder(
    column: $table.noteSourceHost,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get noteId => $composableBuilder(
    column: $table.noteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get receivedAt => $composableBuilder(
    column: $table.receivedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TimelineItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TimelineItemsTable> {
  $$TimelineItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<String> get timelineKey => $composableBuilder(
    column: $table.timelineKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get noteSourceHost => $composableBuilder(
    column: $table.noteSourceHost,
    builder: (column) => column,
  );

  GeneratedColumn<String> get noteId =>
      $composableBuilder(column: $table.noteId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get receivedAt => $composableBuilder(
    column: $table.receivedAt,
    builder: (column) => column,
  );
}

class $$TimelineItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TimelineItemsTable,
          TimelineItemRow,
          $$TimelineItemsTableFilterComposer,
          $$TimelineItemsTableOrderingComposer,
          $$TimelineItemsTableAnnotationComposer,
          $$TimelineItemsTableCreateCompanionBuilder,
          $$TimelineItemsTableUpdateCompanionBuilder,
          (
            TimelineItemRow,
            BaseReferences<_$AppDatabase, $TimelineItemsTable, TimelineItemRow>,
          ),
          TimelineItemRow,
          PrefetchHooks Function()
        > {
  $$TimelineItemsTableTableManager(_$AppDatabase db, $TimelineItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$TimelineItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () =>
                  $$TimelineItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$TimelineItemsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> accountId = const Value.absent(),
                Value<String> timelineKey = const Value.absent(),
                Value<String> noteSourceHost = const Value.absent(),
                Value<String> noteId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> receivedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TimelineItemsCompanion(
                accountId: accountId,
                timelineKey: timelineKey,
                noteSourceHost: noteSourceHost,
                noteId: noteId,
                createdAt: createdAt,
                receivedAt: receivedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String accountId,
                required String timelineKey,
                required String noteSourceHost,
                required String noteId,
                required DateTime createdAt,
                required DateTime receivedAt,
                Value<int> rowid = const Value.absent(),
              }) => TimelineItemsCompanion.insert(
                accountId: accountId,
                timelineKey: timelineKey,
                noteSourceHost: noteSourceHost,
                noteId: noteId,
                createdAt: createdAt,
                receivedAt: receivedAt,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TimelineItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TimelineItemsTable,
      TimelineItemRow,
      $$TimelineItemsTableFilterComposer,
      $$TimelineItemsTableOrderingComposer,
      $$TimelineItemsTableAnnotationComposer,
      $$TimelineItemsTableCreateCompanionBuilder,
      $$TimelineItemsTableUpdateCompanionBuilder,
      (
        TimelineItemRow,
        BaseReferences<_$AppDatabase, $TimelineItemsTable, TimelineItemRow>,
      ),
      TimelineItemRow,
      PrefetchHooks Function()
    >;
typedef $$HeightCacheTableCreateCompanionBuilder =
    HeightCacheCompanion Function({
      required String host,
      required String noteId,
      required int revision,
      required double width,
      required double textScale,
      required String themeId,
      required bool cwExpanded,
      required String mfmSettingsHash,
      required double height,
      required DateTime computedAt,
      Value<int> rowid,
    });
typedef $$HeightCacheTableUpdateCompanionBuilder =
    HeightCacheCompanion Function({
      Value<String> host,
      Value<String> noteId,
      Value<int> revision,
      Value<double> width,
      Value<double> textScale,
      Value<String> themeId,
      Value<bool> cwExpanded,
      Value<String> mfmSettingsHash,
      Value<double> height,
      Value<DateTime> computedAt,
      Value<int> rowid,
    });

class $$HeightCacheTableFilterComposer
    extends Composer<_$AppDatabase, $HeightCacheTable> {
  $$HeightCacheTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get host => $composableBuilder(
    column: $table.host,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get noteId => $composableBuilder(
    column: $table.noteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get width => $composableBuilder(
    column: $table.width,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get textScale => $composableBuilder(
    column: $table.textScale,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get themeId => $composableBuilder(
    column: $table.themeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get cwExpanded => $composableBuilder(
    column: $table.cwExpanded,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mfmSettingsHash => $composableBuilder(
    column: $table.mfmSettingsHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get height => $composableBuilder(
    column: $table.height,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get computedAt => $composableBuilder(
    column: $table.computedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$HeightCacheTableOrderingComposer
    extends Composer<_$AppDatabase, $HeightCacheTable> {
  $$HeightCacheTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get host => $composableBuilder(
    column: $table.host,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get noteId => $composableBuilder(
    column: $table.noteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get width => $composableBuilder(
    column: $table.width,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get textScale => $composableBuilder(
    column: $table.textScale,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get themeId => $composableBuilder(
    column: $table.themeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get cwExpanded => $composableBuilder(
    column: $table.cwExpanded,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mfmSettingsHash => $composableBuilder(
    column: $table.mfmSettingsHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get height => $composableBuilder(
    column: $table.height,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get computedAt => $composableBuilder(
    column: $table.computedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$HeightCacheTableAnnotationComposer
    extends Composer<_$AppDatabase, $HeightCacheTable> {
  $$HeightCacheTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get host =>
      $composableBuilder(column: $table.host, builder: (column) => column);

  GeneratedColumn<String> get noteId =>
      $composableBuilder(column: $table.noteId, builder: (column) => column);

  GeneratedColumn<int> get revision =>
      $composableBuilder(column: $table.revision, builder: (column) => column);

  GeneratedColumn<double> get width =>
      $composableBuilder(column: $table.width, builder: (column) => column);

  GeneratedColumn<double> get textScale =>
      $composableBuilder(column: $table.textScale, builder: (column) => column);

  GeneratedColumn<String> get themeId =>
      $composableBuilder(column: $table.themeId, builder: (column) => column);

  GeneratedColumn<bool> get cwExpanded => $composableBuilder(
    column: $table.cwExpanded,
    builder: (column) => column,
  );

  GeneratedColumn<String> get mfmSettingsHash => $composableBuilder(
    column: $table.mfmSettingsHash,
    builder: (column) => column,
  );

  GeneratedColumn<double> get height =>
      $composableBuilder(column: $table.height, builder: (column) => column);

  GeneratedColumn<DateTime> get computedAt => $composableBuilder(
    column: $table.computedAt,
    builder: (column) => column,
  );
}

class $$HeightCacheTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $HeightCacheTable,
          HeightCacheRow,
          $$HeightCacheTableFilterComposer,
          $$HeightCacheTableOrderingComposer,
          $$HeightCacheTableAnnotationComposer,
          $$HeightCacheTableCreateCompanionBuilder,
          $$HeightCacheTableUpdateCompanionBuilder,
          (
            HeightCacheRow,
            BaseReferences<_$AppDatabase, $HeightCacheTable, HeightCacheRow>,
          ),
          HeightCacheRow,
          PrefetchHooks Function()
        > {
  $$HeightCacheTableTableManager(_$AppDatabase db, $HeightCacheTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$HeightCacheTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$HeightCacheTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () =>
                  $$HeightCacheTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> host = const Value.absent(),
                Value<String> noteId = const Value.absent(),
                Value<int> revision = const Value.absent(),
                Value<double> width = const Value.absent(),
                Value<double> textScale = const Value.absent(),
                Value<String> themeId = const Value.absent(),
                Value<bool> cwExpanded = const Value.absent(),
                Value<String> mfmSettingsHash = const Value.absent(),
                Value<double> height = const Value.absent(),
                Value<DateTime> computedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HeightCacheCompanion(
                host: host,
                noteId: noteId,
                revision: revision,
                width: width,
                textScale: textScale,
                themeId: themeId,
                cwExpanded: cwExpanded,
                mfmSettingsHash: mfmSettingsHash,
                height: height,
                computedAt: computedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String host,
                required String noteId,
                required int revision,
                required double width,
                required double textScale,
                required String themeId,
                required bool cwExpanded,
                required String mfmSettingsHash,
                required double height,
                required DateTime computedAt,
                Value<int> rowid = const Value.absent(),
              }) => HeightCacheCompanion.insert(
                host: host,
                noteId: noteId,
                revision: revision,
                width: width,
                textScale: textScale,
                themeId: themeId,
                cwExpanded: cwExpanded,
                mfmSettingsHash: mfmSettingsHash,
                height: height,
                computedAt: computedAt,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$HeightCacheTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $HeightCacheTable,
      HeightCacheRow,
      $$HeightCacheTableFilterComposer,
      $$HeightCacheTableOrderingComposer,
      $$HeightCacheTableAnnotationComposer,
      $$HeightCacheTableCreateCompanionBuilder,
      $$HeightCacheTableUpdateCompanionBuilder,
      (
        HeightCacheRow,
        BaseReferences<_$AppDatabase, $HeightCacheTable, HeightCacheRow>,
      ),
      HeightCacheRow,
      PrefetchHooks Function()
    >;
typedef $$ReactionRecentsTableCreateCompanionBuilder =
    ReactionRecentsCompanion Function({
      required String accountId,
      required String reactionKey,
      Value<int> useCount,
      required DateTime lastUsedAt,
      Value<int> rowid,
    });
typedef $$ReactionRecentsTableUpdateCompanionBuilder =
    ReactionRecentsCompanion Function({
      Value<String> accountId,
      Value<String> reactionKey,
      Value<int> useCount,
      Value<DateTime> lastUsedAt,
      Value<int> rowid,
    });

class $$ReactionRecentsTableFilterComposer
    extends Composer<_$AppDatabase, $ReactionRecentsTable> {
  $$ReactionRecentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reactionKey => $composableBuilder(
    column: $table.reactionKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get useCount => $composableBuilder(
    column: $table.useCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastUsedAt => $composableBuilder(
    column: $table.lastUsedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ReactionRecentsTableOrderingComposer
    extends Composer<_$AppDatabase, $ReactionRecentsTable> {
  $$ReactionRecentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reactionKey => $composableBuilder(
    column: $table.reactionKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get useCount => $composableBuilder(
    column: $table.useCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastUsedAt => $composableBuilder(
    column: $table.lastUsedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ReactionRecentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReactionRecentsTable> {
  $$ReactionRecentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<String> get reactionKey => $composableBuilder(
    column: $table.reactionKey,
    builder: (column) => column,
  );

  GeneratedColumn<int> get useCount =>
      $composableBuilder(column: $table.useCount, builder: (column) => column);

  GeneratedColumn<DateTime> get lastUsedAt => $composableBuilder(
    column: $table.lastUsedAt,
    builder: (column) => column,
  );
}

class $$ReactionRecentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReactionRecentsTable,
          ReactionRecentRow,
          $$ReactionRecentsTableFilterComposer,
          $$ReactionRecentsTableOrderingComposer,
          $$ReactionRecentsTableAnnotationComposer,
          $$ReactionRecentsTableCreateCompanionBuilder,
          $$ReactionRecentsTableUpdateCompanionBuilder,
          (
            ReactionRecentRow,
            BaseReferences<
              _$AppDatabase,
              $ReactionRecentsTable,
              ReactionRecentRow
            >,
          ),
          ReactionRecentRow,
          PrefetchHooks Function()
        > {
  $$ReactionRecentsTableTableManager(
    _$AppDatabase db,
    $ReactionRecentsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () =>
                  $$ReactionRecentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$ReactionRecentsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer:
              () => $$ReactionRecentsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> accountId = const Value.absent(),
                Value<String> reactionKey = const Value.absent(),
                Value<int> useCount = const Value.absent(),
                Value<DateTime> lastUsedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReactionRecentsCompanion(
                accountId: accountId,
                reactionKey: reactionKey,
                useCount: useCount,
                lastUsedAt: lastUsedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String accountId,
                required String reactionKey,
                Value<int> useCount = const Value.absent(),
                required DateTime lastUsedAt,
                Value<int> rowid = const Value.absent(),
              }) => ReactionRecentsCompanion.insert(
                accountId: accountId,
                reactionKey: reactionKey,
                useCount: useCount,
                lastUsedAt: lastUsedAt,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ReactionRecentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReactionRecentsTable,
      ReactionRecentRow,
      $$ReactionRecentsTableFilterComposer,
      $$ReactionRecentsTableOrderingComposer,
      $$ReactionRecentsTableAnnotationComposer,
      $$ReactionRecentsTableCreateCompanionBuilder,
      $$ReactionRecentsTableUpdateCompanionBuilder,
      (
        ReactionRecentRow,
        BaseReferences<_$AppDatabase, $ReactionRecentsTable, ReactionRecentRow>,
      ),
      ReactionRecentRow,
      PrefetchHooks Function()
    >;
typedef $$DraftsTableCreateCompanionBuilder =
    DraftsCompanion Function({
      required String id,
      required String accountId,
      Value<String?> body,
      Value<String?> cw,
      Value<String> visibility,
      Value<bool> localOnly,
      Value<String?> replyId,
      Value<String?> renoteId,
      Value<String?> sourceNoteUri,
      Value<String?> sourceHost,
      Value<String?> fileIdsJson,
      Value<String?> channelId,
      Value<String?> channelName,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$DraftsTableUpdateCompanionBuilder =
    DraftsCompanion Function({
      Value<String> id,
      Value<String> accountId,
      Value<String?> body,
      Value<String?> cw,
      Value<String> visibility,
      Value<bool> localOnly,
      Value<String?> replyId,
      Value<String?> renoteId,
      Value<String?> sourceNoteUri,
      Value<String?> sourceHost,
      Value<String?> fileIdsJson,
      Value<String?> channelId,
      Value<String?> channelName,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$DraftsTableFilterComposer
    extends Composer<_$AppDatabase, $DraftsTable> {
  $$DraftsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cw => $composableBuilder(
    column: $table.cw,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get visibility => $composableBuilder(
    column: $table.visibility,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get localOnly => $composableBuilder(
    column: $table.localOnly,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get replyId => $composableBuilder(
    column: $table.replyId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get renoteId => $composableBuilder(
    column: $table.renoteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceNoteUri => $composableBuilder(
    column: $table.sourceNoteUri,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceHost => $composableBuilder(
    column: $table.sourceHost,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileIdsJson => $composableBuilder(
    column: $table.fileIdsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get channelId => $composableBuilder(
    column: $table.channelId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get channelName => $composableBuilder(
    column: $table.channelName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DraftsTableOrderingComposer
    extends Composer<_$AppDatabase, $DraftsTable> {
  $$DraftsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cw => $composableBuilder(
    column: $table.cw,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get visibility => $composableBuilder(
    column: $table.visibility,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get localOnly => $composableBuilder(
    column: $table.localOnly,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get replyId => $composableBuilder(
    column: $table.replyId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get renoteId => $composableBuilder(
    column: $table.renoteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceNoteUri => $composableBuilder(
    column: $table.sourceNoteUri,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceHost => $composableBuilder(
    column: $table.sourceHost,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileIdsJson => $composableBuilder(
    column: $table.fileIdsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get channelId => $composableBuilder(
    column: $table.channelId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get channelName => $composableBuilder(
    column: $table.channelName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DraftsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DraftsTable> {
  $$DraftsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<String> get cw =>
      $composableBuilder(column: $table.cw, builder: (column) => column);

  GeneratedColumn<String> get visibility => $composableBuilder(
    column: $table.visibility,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get localOnly =>
      $composableBuilder(column: $table.localOnly, builder: (column) => column);

  GeneratedColumn<String> get replyId =>
      $composableBuilder(column: $table.replyId, builder: (column) => column);

  GeneratedColumn<String> get renoteId =>
      $composableBuilder(column: $table.renoteId, builder: (column) => column);

  GeneratedColumn<String> get sourceNoteUri => $composableBuilder(
    column: $table.sourceNoteUri,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceHost => $composableBuilder(
    column: $table.sourceHost,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fileIdsJson => $composableBuilder(
    column: $table.fileIdsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get channelId =>
      $composableBuilder(column: $table.channelId, builder: (column) => column);

  GeneratedColumn<String> get channelName => $composableBuilder(
    column: $table.channelName,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$DraftsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DraftsTable,
          DraftRow,
          $$DraftsTableFilterComposer,
          $$DraftsTableOrderingComposer,
          $$DraftsTableAnnotationComposer,
          $$DraftsTableCreateCompanionBuilder,
          $$DraftsTableUpdateCompanionBuilder,
          (DraftRow, BaseReferences<_$AppDatabase, $DraftsTable, DraftRow>),
          DraftRow,
          PrefetchHooks Function()
        > {
  $$DraftsTableTableManager(_$AppDatabase db, $DraftsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$DraftsTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$DraftsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$DraftsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> accountId = const Value.absent(),
                Value<String?> body = const Value.absent(),
                Value<String?> cw = const Value.absent(),
                Value<String> visibility = const Value.absent(),
                Value<bool> localOnly = const Value.absent(),
                Value<String?> replyId = const Value.absent(),
                Value<String?> renoteId = const Value.absent(),
                Value<String?> sourceNoteUri = const Value.absent(),
                Value<String?> sourceHost = const Value.absent(),
                Value<String?> fileIdsJson = const Value.absent(),
                Value<String?> channelId = const Value.absent(),
                Value<String?> channelName = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DraftsCompanion(
                id: id,
                accountId: accountId,
                body: body,
                cw: cw,
                visibility: visibility,
                localOnly: localOnly,
                replyId: replyId,
                renoteId: renoteId,
                sourceNoteUri: sourceNoteUri,
                sourceHost: sourceHost,
                fileIdsJson: fileIdsJson,
                channelId: channelId,
                channelName: channelName,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String accountId,
                Value<String?> body = const Value.absent(),
                Value<String?> cw = const Value.absent(),
                Value<String> visibility = const Value.absent(),
                Value<bool> localOnly = const Value.absent(),
                Value<String?> replyId = const Value.absent(),
                Value<String?> renoteId = const Value.absent(),
                Value<String?> sourceNoteUri = const Value.absent(),
                Value<String?> sourceHost = const Value.absent(),
                Value<String?> fileIdsJson = const Value.absent(),
                Value<String?> channelId = const Value.absent(),
                Value<String?> channelName = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => DraftsCompanion.insert(
                id: id,
                accountId: accountId,
                body: body,
                cw: cw,
                visibility: visibility,
                localOnly: localOnly,
                replyId: replyId,
                renoteId: renoteId,
                sourceNoteUri: sourceNoteUri,
                sourceHost: sourceHost,
                fileIdsJson: fileIdsJson,
                channelId: channelId,
                channelName: channelName,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DraftsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DraftsTable,
      DraftRow,
      $$DraftsTableFilterComposer,
      $$DraftsTableOrderingComposer,
      $$DraftsTableAnnotationComposer,
      $$DraftsTableCreateCompanionBuilder,
      $$DraftsTableUpdateCompanionBuilder,
      (DraftRow, BaseReferences<_$AppDatabase, $DraftsTable, DraftRow>),
      DraftRow,
      PrefetchHooks Function()
    >;
typedef $$CustomTimelinesTableCreateCompanionBuilder =
    CustomTimelinesCompanion Function({
      required String id,
      required String name,
      Value<int> sortOrder,
      required String sourcesJson,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$CustomTimelinesTableUpdateCompanionBuilder =
    CustomTimelinesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<int> sortOrder,
      Value<String> sourcesJson,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$CustomTimelinesTableFilterComposer
    extends Composer<_$AppDatabase, $CustomTimelinesTable> {
  $$CustomTimelinesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourcesJson => $composableBuilder(
    column: $table.sourcesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CustomTimelinesTableOrderingComposer
    extends Composer<_$AppDatabase, $CustomTimelinesTable> {
  $$CustomTimelinesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourcesJson => $composableBuilder(
    column: $table.sourcesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CustomTimelinesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CustomTimelinesTable> {
  $$CustomTimelinesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<String> get sourcesJson => $composableBuilder(
    column: $table.sourcesJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$CustomTimelinesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CustomTimelinesTable,
          CustomTimelineRow,
          $$CustomTimelinesTableFilterComposer,
          $$CustomTimelinesTableOrderingComposer,
          $$CustomTimelinesTableAnnotationComposer,
          $$CustomTimelinesTableCreateCompanionBuilder,
          $$CustomTimelinesTableUpdateCompanionBuilder,
          (
            CustomTimelineRow,
            BaseReferences<
              _$AppDatabase,
              $CustomTimelinesTable,
              CustomTimelineRow
            >,
          ),
          CustomTimelineRow,
          PrefetchHooks Function()
        > {
  $$CustomTimelinesTableTableManager(
    _$AppDatabase db,
    $CustomTimelinesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () =>
                  $$CustomTimelinesTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$CustomTimelinesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer:
              () => $$CustomTimelinesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<String> sourcesJson = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CustomTimelinesCompanion(
                id: id,
                name: name,
                sortOrder: sortOrder,
                sourcesJson: sourcesJson,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<int> sortOrder = const Value.absent(),
                required String sourcesJson,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => CustomTimelinesCompanion.insert(
                id: id,
                name: name,
                sortOrder: sortOrder,
                sourcesJson: sourcesJson,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CustomTimelinesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CustomTimelinesTable,
      CustomTimelineRow,
      $$CustomTimelinesTableFilterComposer,
      $$CustomTimelinesTableOrderingComposer,
      $$CustomTimelinesTableAnnotationComposer,
      $$CustomTimelinesTableCreateCompanionBuilder,
      $$CustomTimelinesTableUpdateCompanionBuilder,
      (
        CustomTimelineRow,
        BaseReferences<_$AppDatabase, $CustomTimelinesTable, CustomTimelineRow>,
      ),
      CustomTimelineRow,
      PrefetchHooks Function()
    >;
typedef $$AppPreferencesTableCreateCompanionBuilder =
    AppPreferencesCompanion Function({
      Value<String> id,
      Value<String> themeMode,
      Value<double> textScale,
      Value<bool> disableAnimatedMfm,
      Value<String> reducedMotionOverride,
      Value<bool> blurSensitiveChannels,
      Value<bool> automaticUpdateChecks,
      Value<DateTime?> lastUpdateCheckAt,
      Value<int?> dismissedUpdateVersionCode,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$AppPreferencesTableUpdateCompanionBuilder =
    AppPreferencesCompanion Function({
      Value<String> id,
      Value<String> themeMode,
      Value<double> textScale,
      Value<bool> disableAnimatedMfm,
      Value<String> reducedMotionOverride,
      Value<bool> blurSensitiveChannels,
      Value<bool> automaticUpdateChecks,
      Value<DateTime?> lastUpdateCheckAt,
      Value<int?> dismissedUpdateVersionCode,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$AppPreferencesTableFilterComposer
    extends Composer<_$AppDatabase, $AppPreferencesTable> {
  $$AppPreferencesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get themeMode => $composableBuilder(
    column: $table.themeMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get textScale => $composableBuilder(
    column: $table.textScale,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get disableAnimatedMfm => $composableBuilder(
    column: $table.disableAnimatedMfm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reducedMotionOverride => $composableBuilder(
    column: $table.reducedMotionOverride,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get blurSensitiveChannels => $composableBuilder(
    column: $table.blurSensitiveChannels,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get automaticUpdateChecks => $composableBuilder(
    column: $table.automaticUpdateChecks,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastUpdateCheckAt => $composableBuilder(
    column: $table.lastUpdateCheckAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dismissedUpdateVersionCode => $composableBuilder(
    column: $table.dismissedUpdateVersionCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppPreferencesTableOrderingComposer
    extends Composer<_$AppDatabase, $AppPreferencesTable> {
  $$AppPreferencesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get themeMode => $composableBuilder(
    column: $table.themeMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get textScale => $composableBuilder(
    column: $table.textScale,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get disableAnimatedMfm => $composableBuilder(
    column: $table.disableAnimatedMfm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reducedMotionOverride => $composableBuilder(
    column: $table.reducedMotionOverride,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get blurSensitiveChannels => $composableBuilder(
    column: $table.blurSensitiveChannels,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get automaticUpdateChecks => $composableBuilder(
    column: $table.automaticUpdateChecks,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastUpdateCheckAt => $composableBuilder(
    column: $table.lastUpdateCheckAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dismissedUpdateVersionCode => $composableBuilder(
    column: $table.dismissedUpdateVersionCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppPreferencesTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppPreferencesTable> {
  $$AppPreferencesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get themeMode =>
      $composableBuilder(column: $table.themeMode, builder: (column) => column);

  GeneratedColumn<double> get textScale =>
      $composableBuilder(column: $table.textScale, builder: (column) => column);

  GeneratedColumn<bool> get disableAnimatedMfm => $composableBuilder(
    column: $table.disableAnimatedMfm,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reducedMotionOverride => $composableBuilder(
    column: $table.reducedMotionOverride,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get blurSensitiveChannels => $composableBuilder(
    column: $table.blurSensitiveChannels,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get automaticUpdateChecks => $composableBuilder(
    column: $table.automaticUpdateChecks,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastUpdateCheckAt => $composableBuilder(
    column: $table.lastUpdateCheckAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get dismissedUpdateVersionCode => $composableBuilder(
    column: $table.dismissedUpdateVersionCode,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$AppPreferencesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppPreferencesTable,
          AppPreferenceRow,
          $$AppPreferencesTableFilterComposer,
          $$AppPreferencesTableOrderingComposer,
          $$AppPreferencesTableAnnotationComposer,
          $$AppPreferencesTableCreateCompanionBuilder,
          $$AppPreferencesTableUpdateCompanionBuilder,
          (
            AppPreferenceRow,
            BaseReferences<
              _$AppDatabase,
              $AppPreferencesTable,
              AppPreferenceRow
            >,
          ),
          AppPreferenceRow,
          PrefetchHooks Function()
        > {
  $$AppPreferencesTableTableManager(
    _$AppDatabase db,
    $AppPreferencesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$AppPreferencesTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () =>
                  $$AppPreferencesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$AppPreferencesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> themeMode = const Value.absent(),
                Value<double> textScale = const Value.absent(),
                Value<bool> disableAnimatedMfm = const Value.absent(),
                Value<String> reducedMotionOverride = const Value.absent(),
                Value<bool> blurSensitiveChannels = const Value.absent(),
                Value<bool> automaticUpdateChecks = const Value.absent(),
                Value<DateTime?> lastUpdateCheckAt = const Value.absent(),
                Value<int?> dismissedUpdateVersionCode = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AppPreferencesCompanion(
                id: id,
                themeMode: themeMode,
                textScale: textScale,
                disableAnimatedMfm: disableAnimatedMfm,
                reducedMotionOverride: reducedMotionOverride,
                blurSensitiveChannels: blurSensitiveChannels,
                automaticUpdateChecks: automaticUpdateChecks,
                lastUpdateCheckAt: lastUpdateCheckAt,
                dismissedUpdateVersionCode: dismissedUpdateVersionCode,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> themeMode = const Value.absent(),
                Value<double> textScale = const Value.absent(),
                Value<bool> disableAnimatedMfm = const Value.absent(),
                Value<String> reducedMotionOverride = const Value.absent(),
                Value<bool> blurSensitiveChannels = const Value.absent(),
                Value<bool> automaticUpdateChecks = const Value.absent(),
                Value<DateTime?> lastUpdateCheckAt = const Value.absent(),
                Value<int?> dismissedUpdateVersionCode = const Value.absent(),
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => AppPreferencesCompanion.insert(
                id: id,
                themeMode: themeMode,
                textScale: textScale,
                disableAnimatedMfm: disableAnimatedMfm,
                reducedMotionOverride: reducedMotionOverride,
                blurSensitiveChannels: blurSensitiveChannels,
                automaticUpdateChecks: automaticUpdateChecks,
                lastUpdateCheckAt: lastUpdateCheckAt,
                dismissedUpdateVersionCode: dismissedUpdateVersionCode,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppPreferencesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppPreferencesTable,
      AppPreferenceRow,
      $$AppPreferencesTableFilterComposer,
      $$AppPreferencesTableOrderingComposer,
      $$AppPreferencesTableAnnotationComposer,
      $$AppPreferencesTableCreateCompanionBuilder,
      $$AppPreferencesTableUpdateCompanionBuilder,
      (
        AppPreferenceRow,
        BaseReferences<_$AppDatabase, $AppPreferencesTable, AppPreferenceRow>,
      ),
      AppPreferenceRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ServersTableTableManager get servers =>
      $$ServersTableTableManager(_db, _db.servers);
  $$AccountsTableTableManager get accounts =>
      $$AccountsTableTableManager(_db, _db.accounts);
  $$UsersTableTableManager get users =>
      $$UsersTableTableManager(_db, _db.users);
  $$NotesTableTableManager get notes =>
      $$NotesTableTableManager(_db, _db.notes);
  $$EmojisTableTableManager get emojis =>
      $$EmojisTableTableManager(_db, _db.emojis);
  $$EmojiCatalogsTableTableManager get emojiCatalogs =>
      $$EmojiCatalogsTableTableManager(_db, _db.emojiCatalogs);
  $$TimelineItemsTableTableManager get timelineItems =>
      $$TimelineItemsTableTableManager(_db, _db.timelineItems);
  $$HeightCacheTableTableManager get heightCache =>
      $$HeightCacheTableTableManager(_db, _db.heightCache);
  $$ReactionRecentsTableTableManager get reactionRecents =>
      $$ReactionRecentsTableTableManager(_db, _db.reactionRecents);
  $$DraftsTableTableManager get drafts =>
      $$DraftsTableTableManager(_db, _db.drafts);
  $$CustomTimelinesTableTableManager get customTimelines =>
      $$CustomTimelinesTableTableManager(_db, _db.customTimelines);
  $$AppPreferencesTableTableManager get appPreferences =>
      $$AppPreferencesTableTableManager(_db, _db.appPreferences);
}
