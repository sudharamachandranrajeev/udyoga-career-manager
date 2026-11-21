// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $JobListingsTable extends JobListings
    with TableInfo<$JobListingsTable, Job> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $JobListingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hlcMeta = const VerificationMeta('hlc');
  @override
  late final GeneratedColumn<String> hlc = GeneratedColumn<String>(
    'hlc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _deletedMeta = const VerificationMeta(
    'deleted',
  );
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _companyMeta = const VerificationMeta(
    'company',
  );
  @override
  late final GeneratedColumn<String> company = GeneratedColumn<String>(
    'company',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _locationMeta = const VerificationMeta(
    'location',
  );
  @override
  late final GeneratedColumn<String> location = GeneratedColumn<String>(
    'location',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _countryMeta = const VerificationMeta(
    'country',
  );
  @override
  late final GeneratedColumn<String> country = GeneratedColumn<String>(
    'country',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _remoteMeta = const VerificationMeta('remote');
  @override
  late final GeneratedColumn<bool> remote = GeneratedColumn<bool>(
    'remote',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("remote" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _salaryMinMeta = const VerificationMeta(
    'salaryMin',
  );
  @override
  late final GeneratedColumn<int> salaryMin = GeneratedColumn<int>(
    'salary_min',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _salaryMaxMeta = const VerificationMeta(
    'salaryMax',
  );
  @override
  late final GeneratedColumn<int> salaryMax = GeneratedColumn<int>(
    'salary_max',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _currencyMeta = const VerificationMeta(
    'currency',
  );
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
    'currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _salaryTextMeta = const VerificationMeta(
    'salaryText',
  );
  @override
  late final GeneratedColumn<String> salaryText = GeneratedColumn<String>(
    'salary_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
    'url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _postedMeta = const VerificationMeta('posted');
  @override
  late final GeneratedColumn<String> posted = GeneratedColumn<String>(
    'posted',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _closingMeta = const VerificationMeta(
    'closing',
  );
  @override
  late final GeneratedColumn<String> closing = GeneratedColumn<String>(
    'closing',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('manual'),
  );
  static const VerificationMeta _sourceIdMeta = const VerificationMeta(
    'sourceId',
  );
  @override
  late final GeneratedColumn<String> sourceId = GeneratedColumn<String>(
    'source_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _foundMeta = const VerificationMeta('found');
  @override
  late final GeneratedColumn<String> found = GeneratedColumn<String>(
    'found',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('new'),
  );
  static const VerificationMeta _fitMeta = const VerificationMeta('fit');
  @override
  late final GeneratedColumn<int> fit = GeneratedColumn<int>(
    'fit',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fitByMeta = const VerificationMeta('fitBy');
  @override
  late final GeneratedColumn<String> fitBy = GeneratedColumn<String>(
    'fit_by',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('local'),
  );
  static const VerificationMeta _assessmentMeta = const VerificationMeta(
    'assessment',
  );
  @override
  late final GeneratedColumn<String> assessment = GeneratedColumn<String>(
    'assessment',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    hlc,
    deleted,
    title,
    company,
    location,
    country,
    remote,
    salaryMin,
    salaryMax,
    currency,
    salaryText,
    url,
    description,
    posted,
    closing,
    source,
    sourceId,
    found,
    status,
    fit,
    fitBy,
    assessment,
    notes,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'job_listings';
  @override
  VerificationContext validateIntegrity(
    Insertable<Job> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('hlc')) {
      context.handle(
        _hlcMeta,
        hlc.isAcceptableOrUnknown(data['hlc']!, _hlcMeta),
      );
    }
    if (data.containsKey('deleted')) {
      context.handle(
        _deletedMeta,
        deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('company')) {
      context.handle(
        _companyMeta,
        company.isAcceptableOrUnknown(data['company']!, _companyMeta),
      );
    }
    if (data.containsKey('location')) {
      context.handle(
        _locationMeta,
        location.isAcceptableOrUnknown(data['location']!, _locationMeta),
      );
    }
    if (data.containsKey('country')) {
      context.handle(
        _countryMeta,
        country.isAcceptableOrUnknown(data['country']!, _countryMeta),
      );
    }
    if (data.containsKey('remote')) {
      context.handle(
        _remoteMeta,
        remote.isAcceptableOrUnknown(data['remote']!, _remoteMeta),
      );
    }
    if (data.containsKey('salary_min')) {
      context.handle(
        _salaryMinMeta,
        salaryMin.isAcceptableOrUnknown(data['salary_min']!, _salaryMinMeta),
      );
    }
    if (data.containsKey('salary_max')) {
      context.handle(
        _salaryMaxMeta,
        salaryMax.isAcceptableOrUnknown(data['salary_max']!, _salaryMaxMeta),
      );
    }
    if (data.containsKey('currency')) {
      context.handle(
        _currencyMeta,
        currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta),
      );
    }
    if (data.containsKey('salary_text')) {
      context.handle(
        _salaryTextMeta,
        salaryText.isAcceptableOrUnknown(data['salary_text']!, _salaryTextMeta),
      );
    }
    if (data.containsKey('url')) {
      context.handle(
        _urlMeta,
        url.isAcceptableOrUnknown(data['url']!, _urlMeta),
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
    if (data.containsKey('posted')) {
      context.handle(
        _postedMeta,
        posted.isAcceptableOrUnknown(data['posted']!, _postedMeta),
      );
    }
    if (data.containsKey('closing')) {
      context.handle(
        _closingMeta,
        closing.isAcceptableOrUnknown(data['closing']!, _closingMeta),
      );
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    if (data.containsKey('source_id')) {
      context.handle(
        _sourceIdMeta,
        sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta),
      );
    }
    if (data.containsKey('found')) {
      context.handle(
        _foundMeta,
        found.isAcceptableOrUnknown(data['found']!, _foundMeta),
      );
    } else if (isInserting) {
      context.missing(_foundMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('fit')) {
      context.handle(
        _fitMeta,
        fit.isAcceptableOrUnknown(data['fit']!, _fitMeta),
      );
    }
    if (data.containsKey('fit_by')) {
      context.handle(
        _fitByMeta,
        fitBy.isAcceptableOrUnknown(data['fit_by']!, _fitByMeta),
      );
    }
    if (data.containsKey('assessment')) {
      context.handle(
        _assessmentMeta,
        assessment.isAcceptableOrUnknown(data['assessment']!, _assessmentMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Job map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Job(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      hlc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hlc'],
      )!,
      deleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      company: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}company'],
      )!,
      location: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location'],
      )!,
      country: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}country'],
      )!,
      remote: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}remote'],
      )!,
      salaryMin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}salary_min'],
      ),
      salaryMax: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}salary_max'],
      ),
      currency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency'],
      )!,
      salaryText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}salary_text'],
      )!,
      url: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}url'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      posted: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}posted'],
      ),
      closing: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}closing'],
      ),
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_id'],
      )!,
      found: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}found'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      fit: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}fit'],
      ),
      fitBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fit_by'],
      )!,
      assessment: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}assessment'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      )!,
    );
  }

  @override
  $JobListingsTable createAlias(String alias) {
    return $JobListingsTable(attachedDatabase, alias);
  }
}

class Job extends DataClass implements Insertable<Job> {
  final String id;
  final String hlc;
  final bool deleted;
  final String title;
  final String company;
  final String location;

  /// ISO 3166 alpha-2, upper case ('GB', 'IE', 'IN'); '' when unknown.
  final String country;
  final bool remote;

  /// Yearly figures in [currency] when the advert gives them.
  final int? salaryMin;
  final int? salaryMax;
  final String currency;

  /// The advert's own wording ("£24,000 - £26,500 a year", "Band 4").
  final String salaryText;
  final String url;
  final String description;
  final String? posted;
  final String? closing;

  /// adzuna | reed | arbeitnow | remotive | jobicy | ai | manual; with the
  /// source's own id, so a refresh updates instead of duplicating.
  final String source;
  final String sourceId;
  final String found;

  /// new | saved | dismissed | applied
  final String status;

  /// 0 to 100: the AI's when it has assessed the job, else the local match.
  final int? fit;

  /// Who set [fit]: local (the offline match, redone whenever the profile
  /// changes) | triage (the AI's quick score) | ai (a full assessment).
  final String fitBy;

  /// The AI's assessment (FitAssessment), '' until asked.
  final String assessment;
  final String notes;
  const Job({
    required this.id,
    required this.hlc,
    required this.deleted,
    required this.title,
    required this.company,
    required this.location,
    required this.country,
    required this.remote,
    this.salaryMin,
    this.salaryMax,
    required this.currency,
    required this.salaryText,
    required this.url,
    required this.description,
    this.posted,
    this.closing,
    required this.source,
    required this.sourceId,
    required this.found,
    required this.status,
    this.fit,
    required this.fitBy,
    required this.assessment,
    required this.notes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['hlc'] = Variable<String>(hlc);
    map['deleted'] = Variable<bool>(deleted);
    map['title'] = Variable<String>(title);
    map['company'] = Variable<String>(company);
    map['location'] = Variable<String>(location);
    map['country'] = Variable<String>(country);
    map['remote'] = Variable<bool>(remote);
    if (!nullToAbsent || salaryMin != null) {
      map['salary_min'] = Variable<int>(salaryMin);
    }
    if (!nullToAbsent || salaryMax != null) {
      map['salary_max'] = Variable<int>(salaryMax);
    }
    map['currency'] = Variable<String>(currency);
    map['salary_text'] = Variable<String>(salaryText);
    map['url'] = Variable<String>(url);
    map['description'] = Variable<String>(description);
    if (!nullToAbsent || posted != null) {
      map['posted'] = Variable<String>(posted);
    }
    if (!nullToAbsent || closing != null) {
      map['closing'] = Variable<String>(closing);
    }
    map['source'] = Variable<String>(source);
    map['source_id'] = Variable<String>(sourceId);
    map['found'] = Variable<String>(found);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || fit != null) {
      map['fit'] = Variable<int>(fit);
    }
    map['fit_by'] = Variable<String>(fitBy);
    map['assessment'] = Variable<String>(assessment);
    map['notes'] = Variable<String>(notes);
    return map;
  }

  JobListingsCompanion toCompanion(bool nullToAbsent) {
    return JobListingsCompanion(
      id: Value(id),
      hlc: Value(hlc),
      deleted: Value(deleted),
      title: Value(title),
      company: Value(company),
      location: Value(location),
      country: Value(country),
      remote: Value(remote),
      salaryMin: salaryMin == null && nullToAbsent
          ? const Value.absent()
          : Value(salaryMin),
      salaryMax: salaryMax == null && nullToAbsent
          ? const Value.absent()
          : Value(salaryMax),
      currency: Value(currency),
      salaryText: Value(salaryText),
      url: Value(url),
      description: Value(description),
      posted: posted == null && nullToAbsent
          ? const Value.absent()
          : Value(posted),
      closing: closing == null && nullToAbsent
          ? const Value.absent()
          : Value(closing),
      source: Value(source),
      sourceId: Value(sourceId),
      found: Value(found),
      status: Value(status),
      fit: fit == null && nullToAbsent ? const Value.absent() : Value(fit),
      fitBy: Value(fitBy),
      assessment: Value(assessment),
      notes: Value(notes),
    );
  }

  factory Job.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Job(
      id: serializer.fromJson<String>(json['id']),
      hlc: serializer.fromJson<String>(json['hlc']),
      deleted: serializer.fromJson<bool>(json['deleted']),
      title: serializer.fromJson<String>(json['title']),
      company: serializer.fromJson<String>(json['company']),
      location: serializer.fromJson<String>(json['location']),
      country: serializer.fromJson<String>(json['country']),
      remote: serializer.fromJson<bool>(json['remote']),
      salaryMin: serializer.fromJson<int?>(json['salaryMin']),
      salaryMax: serializer.fromJson<int?>(json['salaryMax']),
      currency: serializer.fromJson<String>(json['currency']),
      salaryText: serializer.fromJson<String>(json['salaryText']),
      url: serializer.fromJson<String>(json['url']),
      description: serializer.fromJson<String>(json['description']),
      posted: serializer.fromJson<String?>(json['posted']),
      closing: serializer.fromJson<String?>(json['closing']),
      source: serializer.fromJson<String>(json['source']),
      sourceId: serializer.fromJson<String>(json['sourceId']),
      found: serializer.fromJson<String>(json['found']),
      status: serializer.fromJson<String>(json['status']),
      fit: serializer.fromJson<int?>(json['fit']),
      fitBy: serializer.fromJson<String>(json['fitBy']),
      assessment: serializer.fromJson<String>(json['assessment']),
      notes: serializer.fromJson<String>(json['notes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'hlc': serializer.toJson<String>(hlc),
      'deleted': serializer.toJson<bool>(deleted),
      'title': serializer.toJson<String>(title),
      'company': serializer.toJson<String>(company),
      'location': serializer.toJson<String>(location),
      'country': serializer.toJson<String>(country),
      'remote': serializer.toJson<bool>(remote),
      'salaryMin': serializer.toJson<int?>(salaryMin),
      'salaryMax': serializer.toJson<int?>(salaryMax),
      'currency': serializer.toJson<String>(currency),
      'salaryText': serializer.toJson<String>(salaryText),
      'url': serializer.toJson<String>(url),
      'description': serializer.toJson<String>(description),
      'posted': serializer.toJson<String?>(posted),
      'closing': serializer.toJson<String?>(closing),
      'source': serializer.toJson<String>(source),
      'sourceId': serializer.toJson<String>(sourceId),
      'found': serializer.toJson<String>(found),
      'status': serializer.toJson<String>(status),
      'fit': serializer.toJson<int?>(fit),
      'fitBy': serializer.toJson<String>(fitBy),
      'assessment': serializer.toJson<String>(assessment),
      'notes': serializer.toJson<String>(notes),
    };
  }

  Job copyWith({
    String? id,
    String? hlc,
    bool? deleted,
    String? title,
    String? company,
    String? location,
    String? country,
    bool? remote,
    Value<int?> salaryMin = const Value.absent(),
    Value<int?> salaryMax = const Value.absent(),
    String? currency,
    String? salaryText,
    String? url,
    String? description,
    Value<String?> posted = const Value.absent(),
    Value<String?> closing = const Value.absent(),
    String? source,
    String? sourceId,
    String? found,
    String? status,
    Value<int?> fit = const Value.absent(),
    String? fitBy,
    String? assessment,
    String? notes,
  }) => Job(
    id: id ?? this.id,
    hlc: hlc ?? this.hlc,
    deleted: deleted ?? this.deleted,
    title: title ?? this.title,
    company: company ?? this.company,
    location: location ?? this.location,
    country: country ?? this.country,
    remote: remote ?? this.remote,
    salaryMin: salaryMin.present ? salaryMin.value : this.salaryMin,
    salaryMax: salaryMax.present ? salaryMax.value : this.salaryMax,
    currency: currency ?? this.currency,
    salaryText: salaryText ?? this.salaryText,
    url: url ?? this.url,
    description: description ?? this.description,
    posted: posted.present ? posted.value : this.posted,
    closing: closing.present ? closing.value : this.closing,
    source: source ?? this.source,
    sourceId: sourceId ?? this.sourceId,
    found: found ?? this.found,
    status: status ?? this.status,
    fit: fit.present ? fit.value : this.fit,
    fitBy: fitBy ?? this.fitBy,
    assessment: assessment ?? this.assessment,
    notes: notes ?? this.notes,
  );
  Job copyWithCompanion(JobListingsCompanion data) {
    return Job(
      id: data.id.present ? data.id.value : this.id,
      hlc: data.hlc.present ? data.hlc.value : this.hlc,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      title: data.title.present ? data.title.value : this.title,
      company: data.company.present ? data.company.value : this.company,
      location: data.location.present ? data.location.value : this.location,
      country: data.country.present ? data.country.value : this.country,
      remote: data.remote.present ? data.remote.value : this.remote,
      salaryMin: data.salaryMin.present ? data.salaryMin.value : this.salaryMin,
      salaryMax: data.salaryMax.present ? data.salaryMax.value : this.salaryMax,
      currency: data.currency.present ? data.currency.value : this.currency,
      salaryText: data.salaryText.present
          ? data.salaryText.value
          : this.salaryText,
      url: data.url.present ? data.url.value : this.url,
      description: data.description.present
          ? data.description.value
          : this.description,
      posted: data.posted.present ? data.posted.value : this.posted,
      closing: data.closing.present ? data.closing.value : this.closing,
      source: data.source.present ? data.source.value : this.source,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      found: data.found.present ? data.found.value : this.found,
      status: data.status.present ? data.status.value : this.status,
      fit: data.fit.present ? data.fit.value : this.fit,
      fitBy: data.fitBy.present ? data.fitBy.value : this.fitBy,
      assessment: data.assessment.present
          ? data.assessment.value
          : this.assessment,
      notes: data.notes.present ? data.notes.value : this.notes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Job(')
          ..write('id: $id, ')
          ..write('hlc: $hlc, ')
          ..write('deleted: $deleted, ')
          ..write('title: $title, ')
          ..write('company: $company, ')
          ..write('location: $location, ')
          ..write('country: $country, ')
          ..write('remote: $remote, ')
          ..write('salaryMin: $salaryMin, ')
          ..write('salaryMax: $salaryMax, ')
          ..write('currency: $currency, ')
          ..write('salaryText: $salaryText, ')
          ..write('url: $url, ')
          ..write('description: $description, ')
          ..write('posted: $posted, ')
          ..write('closing: $closing, ')
          ..write('source: $source, ')
          ..write('sourceId: $sourceId, ')
          ..write('found: $found, ')
          ..write('status: $status, ')
          ..write('fit: $fit, ')
          ..write('fitBy: $fitBy, ')
          ..write('assessment: $assessment, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    hlc,
    deleted,
    title,
    company,
    location,
    country,
    remote,
    salaryMin,
    salaryMax,
    currency,
    salaryText,
    url,
    description,
    posted,
    closing,
    source,
    sourceId,
    found,
    status,
    fit,
    fitBy,
    assessment,
    notes,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Job &&
          other.id == this.id &&
          other.hlc == this.hlc &&
          other.deleted == this.deleted &&
          other.title == this.title &&
          other.company == this.company &&
          other.location == this.location &&
          other.country == this.country &&
          other.remote == this.remote &&
          other.salaryMin == this.salaryMin &&
          other.salaryMax == this.salaryMax &&
          other.currency == this.currency &&
          other.salaryText == this.salaryText &&
          other.url == this.url &&
          other.description == this.description &&
          other.posted == this.posted &&
          other.closing == this.closing &&
          other.source == this.source &&
          other.sourceId == this.sourceId &&
          other.found == this.found &&
          other.status == this.status &&
          other.fit == this.fit &&
          other.fitBy == this.fitBy &&
          other.assessment == this.assessment &&
          other.notes == this.notes);
}

class JobListingsCompanion extends UpdateCompanion<Job> {
  final Value<String> id;
  final Value<String> hlc;
  final Value<bool> deleted;
  final Value<String> title;
  final Value<String> company;
  final Value<String> location;
  final Value<String> country;
  final Value<bool> remote;
  final Value<int?> salaryMin;
  final Value<int?> salaryMax;
  final Value<String> currency;
  final Value<String> salaryText;
  final Value<String> url;
  final Value<String> description;
  final Value<String?> posted;
  final Value<String?> closing;
  final Value<String> source;
  final Value<String> sourceId;
  final Value<String> found;
  final Value<String> status;
  final Value<int?> fit;
  final Value<String> fitBy;
  final Value<String> assessment;
  final Value<String> notes;
  final Value<int> rowid;
  const JobListingsCompanion({
    this.id = const Value.absent(),
    this.hlc = const Value.absent(),
    this.deleted = const Value.absent(),
    this.title = const Value.absent(),
    this.company = const Value.absent(),
    this.location = const Value.absent(),
    this.country = const Value.absent(),
    this.remote = const Value.absent(),
    this.salaryMin = const Value.absent(),
    this.salaryMax = const Value.absent(),
    this.currency = const Value.absent(),
    this.salaryText = const Value.absent(),
    this.url = const Value.absent(),
    this.description = const Value.absent(),
    this.posted = const Value.absent(),
    this.closing = const Value.absent(),
    this.source = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.found = const Value.absent(),
    this.status = const Value.absent(),
    this.fit = const Value.absent(),
    this.fitBy = const Value.absent(),
    this.assessment = const Value.absent(),
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  JobListingsCompanion.insert({
    required String id,
    this.hlc = const Value.absent(),
    this.deleted = const Value.absent(),
    required String title,
    this.company = const Value.absent(),
    this.location = const Value.absent(),
    this.country = const Value.absent(),
    this.remote = const Value.absent(),
    this.salaryMin = const Value.absent(),
    this.salaryMax = const Value.absent(),
    this.currency = const Value.absent(),
    this.salaryText = const Value.absent(),
    this.url = const Value.absent(),
    this.description = const Value.absent(),
    this.posted = const Value.absent(),
    this.closing = const Value.absent(),
    this.source = const Value.absent(),
    this.sourceId = const Value.absent(),
    required String found,
    this.status = const Value.absent(),
    this.fit = const Value.absent(),
    this.fitBy = const Value.absent(),
    this.assessment = const Value.absent(),
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       found = Value(found);
  static Insertable<Job> custom({
    Expression<String>? id,
    Expression<String>? hlc,
    Expression<bool>? deleted,
    Expression<String>? title,
    Expression<String>? company,
    Expression<String>? location,
    Expression<String>? country,
    Expression<bool>? remote,
    Expression<int>? salaryMin,
    Expression<int>? salaryMax,
    Expression<String>? currency,
    Expression<String>? salaryText,
    Expression<String>? url,
    Expression<String>? description,
    Expression<String>? posted,
    Expression<String>? closing,
    Expression<String>? source,
    Expression<String>? sourceId,
    Expression<String>? found,
    Expression<String>? status,
    Expression<int>? fit,
    Expression<String>? fitBy,
    Expression<String>? assessment,
    Expression<String>? notes,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (hlc != null) 'hlc': hlc,
      if (deleted != null) 'deleted': deleted,
      if (title != null) 'title': title,
      if (company != null) 'company': company,
      if (location != null) 'location': location,
      if (country != null) 'country': country,
      if (remote != null) 'remote': remote,
      if (salaryMin != null) 'salary_min': salaryMin,
      if (salaryMax != null) 'salary_max': salaryMax,
      if (currency != null) 'currency': currency,
      if (salaryText != null) 'salary_text': salaryText,
      if (url != null) 'url': url,
      if (description != null) 'description': description,
      if (posted != null) 'posted': posted,
      if (closing != null) 'closing': closing,
      if (source != null) 'source': source,
      if (sourceId != null) 'source_id': sourceId,
      if (found != null) 'found': found,
      if (status != null) 'status': status,
      if (fit != null) 'fit': fit,
      if (fitBy != null) 'fit_by': fitBy,
      if (assessment != null) 'assessment': assessment,
      if (notes != null) 'notes': notes,
      if (rowid != null) 'rowid': rowid,
    });
  }

  JobListingsCompanion copyWith({
    Value<String>? id,
    Value<String>? hlc,
    Value<bool>? deleted,
    Value<String>? title,
    Value<String>? company,
    Value<String>? location,
    Value<String>? country,
    Value<bool>? remote,
    Value<int?>? salaryMin,
    Value<int?>? salaryMax,
    Value<String>? currency,
    Value<String>? salaryText,
    Value<String>? url,
    Value<String>? description,
    Value<String?>? posted,
    Value<String?>? closing,
    Value<String>? source,
    Value<String>? sourceId,
    Value<String>? found,
    Value<String>? status,
    Value<int?>? fit,
    Value<String>? fitBy,
    Value<String>? assessment,
    Value<String>? notes,
    Value<int>? rowid,
  }) {
    return JobListingsCompanion(
      id: id ?? this.id,
      hlc: hlc ?? this.hlc,
      deleted: deleted ?? this.deleted,
      title: title ?? this.title,
      company: company ?? this.company,
      location: location ?? this.location,
      country: country ?? this.country,
      remote: remote ?? this.remote,
      salaryMin: salaryMin ?? this.salaryMin,
      salaryMax: salaryMax ?? this.salaryMax,
      currency: currency ?? this.currency,
      salaryText: salaryText ?? this.salaryText,
      url: url ?? this.url,
      description: description ?? this.description,
      posted: posted ?? this.posted,
      closing: closing ?? this.closing,
      source: source ?? this.source,
      sourceId: sourceId ?? this.sourceId,
      found: found ?? this.found,
      status: status ?? this.status,
      fit: fit ?? this.fit,
      fitBy: fitBy ?? this.fitBy,
      assessment: assessment ?? this.assessment,
      notes: notes ?? this.notes,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (hlc.present) {
      map['hlc'] = Variable<String>(hlc.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (company.present) {
      map['company'] = Variable<String>(company.value);
    }
    if (location.present) {
      map['location'] = Variable<String>(location.value);
    }
    if (country.present) {
      map['country'] = Variable<String>(country.value);
    }
    if (remote.present) {
      map['remote'] = Variable<bool>(remote.value);
    }
    if (salaryMin.present) {
      map['salary_min'] = Variable<int>(salaryMin.value);
    }
    if (salaryMax.present) {
      map['salary_max'] = Variable<int>(salaryMax.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (salaryText.present) {
      map['salary_text'] = Variable<String>(salaryText.value);
    }
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (posted.present) {
      map['posted'] = Variable<String>(posted.value);
    }
    if (closing.present) {
      map['closing'] = Variable<String>(closing.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (sourceId.present) {
      map['source_id'] = Variable<String>(sourceId.value);
    }
    if (found.present) {
      map['found'] = Variable<String>(found.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (fit.present) {
      map['fit'] = Variable<int>(fit.value);
    }
    if (fitBy.present) {
      map['fit_by'] = Variable<String>(fitBy.value);
    }
    if (assessment.present) {
      map['assessment'] = Variable<String>(assessment.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('JobListingsCompanion(')
          ..write('id: $id, ')
          ..write('hlc: $hlc, ')
          ..write('deleted: $deleted, ')
          ..write('title: $title, ')
          ..write('company: $company, ')
          ..write('location: $location, ')
          ..write('country: $country, ')
          ..write('remote: $remote, ')
          ..write('salaryMin: $salaryMin, ')
          ..write('salaryMax: $salaryMax, ')
          ..write('currency: $currency, ')
          ..write('salaryText: $salaryText, ')
          ..write('url: $url, ')
          ..write('description: $description, ')
          ..write('posted: $posted, ')
          ..write('closing: $closing, ')
          ..write('source: $source, ')
          ..write('sourceId: $sourceId, ')
          ..write('found: $found, ')
          ..write('status: $status, ')
          ..write('fit: $fit, ')
          ..write('fitBy: $fitBy, ')
          ..write('assessment: $assessment, ')
          ..write('notes: $notes, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $JobApplicationsTable extends JobApplications
    with TableInfo<$JobApplicationsTable, JobApplication> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $JobApplicationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hlcMeta = const VerificationMeta('hlc');
  @override
  late final GeneratedColumn<String> hlc = GeneratedColumn<String>(
    'hlc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _deletedMeta = const VerificationMeta(
    'deleted',
  );
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _jobIdMeta = const VerificationMeta('jobId');
  @override
  late final GeneratedColumn<String> jobId = GeneratedColumn<String>(
    'job_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _companyMeta = const VerificationMeta(
    'company',
  );
  @override
  late final GeneratedColumn<String> company = GeneratedColumn<String>(
    'company',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _locationMeta = const VerificationMeta(
    'location',
  );
  @override
  late final GeneratedColumn<String> location = GeneratedColumn<String>(
    'location',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
    'url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _stageMeta = const VerificationMeta('stage');
  @override
  late final GeneratedColumn<String> stage = GeneratedColumn<String>(
    'stage',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('preparing'),
  );
  static const VerificationMeta _appliedMeta = const VerificationMeta(
    'applied',
  );
  @override
  late final GeneratedColumn<String> applied = GeneratedColumn<String>(
    'applied',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _followUpMeta = const VerificationMeta(
    'followUp',
  );
  @override
  late final GeneratedColumn<String> followUp = GeneratedColumn<String>(
    'follow_up',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _followUpNoteMeta = const VerificationMeta(
    'followUpNote',
  );
  @override
  late final GeneratedColumn<String> followUpNote = GeneratedColumn<String>(
    'follow_up_note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _resumeIdMeta = const VerificationMeta(
    'resumeId',
  );
  @override
  late final GeneratedColumn<String> resumeId = GeneratedColumn<String>(
    'resume_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _referenceMeta = const VerificationMeta(
    'reference',
  );
  @override
  late final GeneratedColumn<String> reference = GeneratedColumn<String>(
    'reference',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _updatedMeta = const VerificationMeta(
    'updated',
  );
  @override
  late final GeneratedColumn<String> updated = GeneratedColumn<String>(
    'updated',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    hlc,
    deleted,
    jobId,
    title,
    company,
    location,
    url,
    stage,
    applied,
    followUp,
    followUpNote,
    resumeId,
    reference,
    notes,
    updated,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'job_applications';
  @override
  VerificationContext validateIntegrity(
    Insertable<JobApplication> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('hlc')) {
      context.handle(
        _hlcMeta,
        hlc.isAcceptableOrUnknown(data['hlc']!, _hlcMeta),
      );
    }
    if (data.containsKey('deleted')) {
      context.handle(
        _deletedMeta,
        deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta),
      );
    }
    if (data.containsKey('job_id')) {
      context.handle(
        _jobIdMeta,
        jobId.isAcceptableOrUnknown(data['job_id']!, _jobIdMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('company')) {
      context.handle(
        _companyMeta,
        company.isAcceptableOrUnknown(data['company']!, _companyMeta),
      );
    }
    if (data.containsKey('location')) {
      context.handle(
        _locationMeta,
        location.isAcceptableOrUnknown(data['location']!, _locationMeta),
      );
    }
    if (data.containsKey('url')) {
      context.handle(
        _urlMeta,
        url.isAcceptableOrUnknown(data['url']!, _urlMeta),
      );
    }
    if (data.containsKey('stage')) {
      context.handle(
        _stageMeta,
        stage.isAcceptableOrUnknown(data['stage']!, _stageMeta),
      );
    }
    if (data.containsKey('applied')) {
      context.handle(
        _appliedMeta,
        applied.isAcceptableOrUnknown(data['applied']!, _appliedMeta),
      );
    }
    if (data.containsKey('follow_up')) {
      context.handle(
        _followUpMeta,
        followUp.isAcceptableOrUnknown(data['follow_up']!, _followUpMeta),
      );
    }
    if (data.containsKey('follow_up_note')) {
      context.handle(
        _followUpNoteMeta,
        followUpNote.isAcceptableOrUnknown(
          data['follow_up_note']!,
          _followUpNoteMeta,
        ),
      );
    }
    if (data.containsKey('resume_id')) {
      context.handle(
        _resumeIdMeta,
        resumeId.isAcceptableOrUnknown(data['resume_id']!, _resumeIdMeta),
      );
    }
    if (data.containsKey('reference')) {
      context.handle(
        _referenceMeta,
        reference.isAcceptableOrUnknown(data['reference']!, _referenceMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('updated')) {
      context.handle(
        _updatedMeta,
        updated.isAcceptableOrUnknown(data['updated']!, _updatedMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  JobApplication map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return JobApplication(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      hlc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hlc'],
      )!,
      deleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted'],
      )!,
      jobId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}job_id'],
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      company: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}company'],
      )!,
      location: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location'],
      )!,
      url: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}url'],
      )!,
      stage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}stage'],
      )!,
      applied: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}applied'],
      ),
      followUp: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}follow_up'],
      ),
      followUpNote: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}follow_up_note'],
      )!,
      resumeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}resume_id'],
      ),
      reference: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reference'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      )!,
      updated: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated'],
      )!,
    );
  }

  @override
  $JobApplicationsTable createAlias(String alias) {
    return $JobApplicationsTable(attachedDatabase, alias);
  }
}

class JobApplication extends DataClass implements Insertable<JobApplication> {
  final String id;
  final String hlc;
  final bool deleted;
  final String? jobId;
  final String title;
  final String company;
  final String location;
  final String url;

  /// See domain/pipeline.dart.
  final String stage;
  final String? applied;

  /// When to chase it up, and what to ask.
  final String? followUp;
  final String followUpNote;

  /// The CV sent (career_resumes id).
  final String? resumeId;
  final String reference;
  final String notes;

  /// Last change of stage, for "no reply in N days".
  final String updated;
  const JobApplication({
    required this.id,
    required this.hlc,
    required this.deleted,
    this.jobId,
    required this.title,
    required this.company,
    required this.location,
    required this.url,
    required this.stage,
    this.applied,
    this.followUp,
    required this.followUpNote,
    this.resumeId,
    required this.reference,
    required this.notes,
    required this.updated,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['hlc'] = Variable<String>(hlc);
    map['deleted'] = Variable<bool>(deleted);
    if (!nullToAbsent || jobId != null) {
      map['job_id'] = Variable<String>(jobId);
    }
    map['title'] = Variable<String>(title);
    map['company'] = Variable<String>(company);
    map['location'] = Variable<String>(location);
    map['url'] = Variable<String>(url);
    map['stage'] = Variable<String>(stage);
    if (!nullToAbsent || applied != null) {
      map['applied'] = Variable<String>(applied);
    }
    if (!nullToAbsent || followUp != null) {
      map['follow_up'] = Variable<String>(followUp);
    }
    map['follow_up_note'] = Variable<String>(followUpNote);
    if (!nullToAbsent || resumeId != null) {
      map['resume_id'] = Variable<String>(resumeId);
    }
    map['reference'] = Variable<String>(reference);
    map['notes'] = Variable<String>(notes);
    map['updated'] = Variable<String>(updated);
    return map;
  }

  JobApplicationsCompanion toCompanion(bool nullToAbsent) {
    return JobApplicationsCompanion(
      id: Value(id),
      hlc: Value(hlc),
      deleted: Value(deleted),
      jobId: jobId == null && nullToAbsent
          ? const Value.absent()
          : Value(jobId),
      title: Value(title),
      company: Value(company),
      location: Value(location),
      url: Value(url),
      stage: Value(stage),
      applied: applied == null && nullToAbsent
          ? const Value.absent()
          : Value(applied),
      followUp: followUp == null && nullToAbsent
          ? const Value.absent()
          : Value(followUp),
      followUpNote: Value(followUpNote),
      resumeId: resumeId == null && nullToAbsent
          ? const Value.absent()
          : Value(resumeId),
      reference: Value(reference),
      notes: Value(notes),
      updated: Value(updated),
    );
  }

  factory JobApplication.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return JobApplication(
      id: serializer.fromJson<String>(json['id']),
      hlc: serializer.fromJson<String>(json['hlc']),
      deleted: serializer.fromJson<bool>(json['deleted']),
      jobId: serializer.fromJson<String?>(json['jobId']),
      title: serializer.fromJson<String>(json['title']),
      company: serializer.fromJson<String>(json['company']),
      location: serializer.fromJson<String>(json['location']),
      url: serializer.fromJson<String>(json['url']),
      stage: serializer.fromJson<String>(json['stage']),
      applied: serializer.fromJson<String?>(json['applied']),
      followUp: serializer.fromJson<String?>(json['followUp']),
      followUpNote: serializer.fromJson<String>(json['followUpNote']),
      resumeId: serializer.fromJson<String?>(json['resumeId']),
      reference: serializer.fromJson<String>(json['reference']),
      notes: serializer.fromJson<String>(json['notes']),
      updated: serializer.fromJson<String>(json['updated']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'hlc': serializer.toJson<String>(hlc),
      'deleted': serializer.toJson<bool>(deleted),
      'jobId': serializer.toJson<String?>(jobId),
      'title': serializer.toJson<String>(title),
      'company': serializer.toJson<String>(company),
      'location': serializer.toJson<String>(location),
      'url': serializer.toJson<String>(url),
      'stage': serializer.toJson<String>(stage),
      'applied': serializer.toJson<String?>(applied),
      'followUp': serializer.toJson<String?>(followUp),
      'followUpNote': serializer.toJson<String>(followUpNote),
      'resumeId': serializer.toJson<String?>(resumeId),
      'reference': serializer.toJson<String>(reference),
      'notes': serializer.toJson<String>(notes),
      'updated': serializer.toJson<String>(updated),
    };
  }

  JobApplication copyWith({
    String? id,
    String? hlc,
    bool? deleted,
    Value<String?> jobId = const Value.absent(),
    String? title,
    String? company,
    String? location,
    String? url,
    String? stage,
    Value<String?> applied = const Value.absent(),
    Value<String?> followUp = const Value.absent(),
    String? followUpNote,
    Value<String?> resumeId = const Value.absent(),
    String? reference,
    String? notes,
    String? updated,
  }) => JobApplication(
    id: id ?? this.id,
    hlc: hlc ?? this.hlc,
    deleted: deleted ?? this.deleted,
    jobId: jobId.present ? jobId.value : this.jobId,
    title: title ?? this.title,
    company: company ?? this.company,
    location: location ?? this.location,
    url: url ?? this.url,
    stage: stage ?? this.stage,
    applied: applied.present ? applied.value : this.applied,
    followUp: followUp.present ? followUp.value : this.followUp,
    followUpNote: followUpNote ?? this.followUpNote,
    resumeId: resumeId.present ? resumeId.value : this.resumeId,
    reference: reference ?? this.reference,
    notes: notes ?? this.notes,
    updated: updated ?? this.updated,
  );
  JobApplication copyWithCompanion(JobApplicationsCompanion data) {
    return JobApplication(
      id: data.id.present ? data.id.value : this.id,
      hlc: data.hlc.present ? data.hlc.value : this.hlc,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      jobId: data.jobId.present ? data.jobId.value : this.jobId,
      title: data.title.present ? data.title.value : this.title,
      company: data.company.present ? data.company.value : this.company,
      location: data.location.present ? data.location.value : this.location,
      url: data.url.present ? data.url.value : this.url,
      stage: data.stage.present ? data.stage.value : this.stage,
      applied: data.applied.present ? data.applied.value : this.applied,
      followUp: data.followUp.present ? data.followUp.value : this.followUp,
      followUpNote: data.followUpNote.present
          ? data.followUpNote.value
          : this.followUpNote,
      resumeId: data.resumeId.present ? data.resumeId.value : this.resumeId,
      reference: data.reference.present ? data.reference.value : this.reference,
      notes: data.notes.present ? data.notes.value : this.notes,
      updated: data.updated.present ? data.updated.value : this.updated,
    );
  }

  @override
  String toString() {
    return (StringBuffer('JobApplication(')
          ..write('id: $id, ')
          ..write('hlc: $hlc, ')
          ..write('deleted: $deleted, ')
          ..write('jobId: $jobId, ')
          ..write('title: $title, ')
          ..write('company: $company, ')
          ..write('location: $location, ')
          ..write('url: $url, ')
          ..write('stage: $stage, ')
          ..write('applied: $applied, ')
          ..write('followUp: $followUp, ')
          ..write('followUpNote: $followUpNote, ')
          ..write('resumeId: $resumeId, ')
          ..write('reference: $reference, ')
          ..write('notes: $notes, ')
          ..write('updated: $updated')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    hlc,
    deleted,
    jobId,
    title,
    company,
    location,
    url,
    stage,
    applied,
    followUp,
    followUpNote,
    resumeId,
    reference,
    notes,
    updated,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is JobApplication &&
          other.id == this.id &&
          other.hlc == this.hlc &&
          other.deleted == this.deleted &&
          other.jobId == this.jobId &&
          other.title == this.title &&
          other.company == this.company &&
          other.location == this.location &&
          other.url == this.url &&
          other.stage == this.stage &&
          other.applied == this.applied &&
          other.followUp == this.followUp &&
          other.followUpNote == this.followUpNote &&
          other.resumeId == this.resumeId &&
          other.reference == this.reference &&
          other.notes == this.notes &&
          other.updated == this.updated);
}

class JobApplicationsCompanion extends UpdateCompanion<JobApplication> {
  final Value<String> id;
  final Value<String> hlc;
  final Value<bool> deleted;
  final Value<String?> jobId;
  final Value<String> title;
  final Value<String> company;
  final Value<String> location;
  final Value<String> url;
  final Value<String> stage;
  final Value<String?> applied;
  final Value<String?> followUp;
  final Value<String> followUpNote;
  final Value<String?> resumeId;
  final Value<String> reference;
  final Value<String> notes;
  final Value<String> updated;
  final Value<int> rowid;
  const JobApplicationsCompanion({
    this.id = const Value.absent(),
    this.hlc = const Value.absent(),
    this.deleted = const Value.absent(),
    this.jobId = const Value.absent(),
    this.title = const Value.absent(),
    this.company = const Value.absent(),
    this.location = const Value.absent(),
    this.url = const Value.absent(),
    this.stage = const Value.absent(),
    this.applied = const Value.absent(),
    this.followUp = const Value.absent(),
    this.followUpNote = const Value.absent(),
    this.resumeId = const Value.absent(),
    this.reference = const Value.absent(),
    this.notes = const Value.absent(),
    this.updated = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  JobApplicationsCompanion.insert({
    required String id,
    this.hlc = const Value.absent(),
    this.deleted = const Value.absent(),
    this.jobId = const Value.absent(),
    required String title,
    this.company = const Value.absent(),
    this.location = const Value.absent(),
    this.url = const Value.absent(),
    this.stage = const Value.absent(),
    this.applied = const Value.absent(),
    this.followUp = const Value.absent(),
    this.followUpNote = const Value.absent(),
    this.resumeId = const Value.absent(),
    this.reference = const Value.absent(),
    this.notes = const Value.absent(),
    required String updated,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       updated = Value(updated);
  static Insertable<JobApplication> custom({
    Expression<String>? id,
    Expression<String>? hlc,
    Expression<bool>? deleted,
    Expression<String>? jobId,
    Expression<String>? title,
    Expression<String>? company,
    Expression<String>? location,
    Expression<String>? url,
    Expression<String>? stage,
    Expression<String>? applied,
    Expression<String>? followUp,
    Expression<String>? followUpNote,
    Expression<String>? resumeId,
    Expression<String>? reference,
    Expression<String>? notes,
    Expression<String>? updated,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (hlc != null) 'hlc': hlc,
      if (deleted != null) 'deleted': deleted,
      if (jobId != null) 'job_id': jobId,
      if (title != null) 'title': title,
      if (company != null) 'company': company,
      if (location != null) 'location': location,
      if (url != null) 'url': url,
      if (stage != null) 'stage': stage,
      if (applied != null) 'applied': applied,
      if (followUp != null) 'follow_up': followUp,
      if (followUpNote != null) 'follow_up_note': followUpNote,
      if (resumeId != null) 'resume_id': resumeId,
      if (reference != null) 'reference': reference,
      if (notes != null) 'notes': notes,
      if (updated != null) 'updated': updated,
      if (rowid != null) 'rowid': rowid,
    });
  }

  JobApplicationsCompanion copyWith({
    Value<String>? id,
    Value<String>? hlc,
    Value<bool>? deleted,
    Value<String?>? jobId,
    Value<String>? title,
    Value<String>? company,
    Value<String>? location,
    Value<String>? url,
    Value<String>? stage,
    Value<String?>? applied,
    Value<String?>? followUp,
    Value<String>? followUpNote,
    Value<String?>? resumeId,
    Value<String>? reference,
    Value<String>? notes,
    Value<String>? updated,
    Value<int>? rowid,
  }) {
    return JobApplicationsCompanion(
      id: id ?? this.id,
      hlc: hlc ?? this.hlc,
      deleted: deleted ?? this.deleted,
      jobId: jobId ?? this.jobId,
      title: title ?? this.title,
      company: company ?? this.company,
      location: location ?? this.location,
      url: url ?? this.url,
      stage: stage ?? this.stage,
      applied: applied ?? this.applied,
      followUp: followUp ?? this.followUp,
      followUpNote: followUpNote ?? this.followUpNote,
      resumeId: resumeId ?? this.resumeId,
      reference: reference ?? this.reference,
      notes: notes ?? this.notes,
      updated: updated ?? this.updated,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (hlc.present) {
      map['hlc'] = Variable<String>(hlc.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (jobId.present) {
      map['job_id'] = Variable<String>(jobId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (company.present) {
      map['company'] = Variable<String>(company.value);
    }
    if (location.present) {
      map['location'] = Variable<String>(location.value);
    }
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (stage.present) {
      map['stage'] = Variable<String>(stage.value);
    }
    if (applied.present) {
      map['applied'] = Variable<String>(applied.value);
    }
    if (followUp.present) {
      map['follow_up'] = Variable<String>(followUp.value);
    }
    if (followUpNote.present) {
      map['follow_up_note'] = Variable<String>(followUpNote.value);
    }
    if (resumeId.present) {
      map['resume_id'] = Variable<String>(resumeId.value);
    }
    if (reference.present) {
      map['reference'] = Variable<String>(reference.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (updated.present) {
      map['updated'] = Variable<String>(updated.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('JobApplicationsCompanion(')
          ..write('id: $id, ')
          ..write('hlc: $hlc, ')
          ..write('deleted: $deleted, ')
          ..write('jobId: $jobId, ')
          ..write('title: $title, ')
          ..write('company: $company, ')
          ..write('location: $location, ')
          ..write('url: $url, ')
          ..write('stage: $stage, ')
          ..write('applied: $applied, ')
          ..write('followUp: $followUp, ')
          ..write('followUpNote: $followUpNote, ')
          ..write('resumeId: $resumeId, ')
          ..write('reference: $reference, ')
          ..write('notes: $notes, ')
          ..write('updated: $updated, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $JobEventsTable extends JobEvents
    with TableInfo<$JobEventsTable, JobEvent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $JobEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hlcMeta = const VerificationMeta('hlc');
  @override
  late final GeneratedColumn<String> hlc = GeneratedColumn<String>(
    'hlc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _deletedMeta = const VerificationMeta(
    'deleted',
  );
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _applicationIdMeta = const VerificationMeta(
    'applicationId',
  );
  @override
  late final GeneratedColumn<String> applicationId = GeneratedColumn<String>(
    'application_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _atMeta = const VerificationMeta('at');
  @override
  late final GeneratedColumn<String> at = GeneratedColumn<String>(
    'at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _summaryMeta = const VerificationMeta(
    'summary',
  );
  @override
  late final GeneratedColumn<String> summary = GeneratedColumn<String>(
    'summary',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    hlc,
    deleted,
    applicationId,
    at,
    kind,
    summary,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'job_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<JobEvent> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('hlc')) {
      context.handle(
        _hlcMeta,
        hlc.isAcceptableOrUnknown(data['hlc']!, _hlcMeta),
      );
    }
    if (data.containsKey('deleted')) {
      context.handle(
        _deletedMeta,
        deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta),
      );
    }
    if (data.containsKey('application_id')) {
      context.handle(
        _applicationIdMeta,
        applicationId.isAcceptableOrUnknown(
          data['application_id']!,
          _applicationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_applicationIdMeta);
    }
    if (data.containsKey('at')) {
      context.handle(_atMeta, at.isAcceptableOrUnknown(data['at']!, _atMeta));
    } else if (isInserting) {
      context.missing(_atMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('summary')) {
      context.handle(
        _summaryMeta,
        summary.isAcceptableOrUnknown(data['summary']!, _summaryMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  JobEvent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return JobEvent(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      hlc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hlc'],
      )!,
      deleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted'],
      )!,
      applicationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}application_id'],
      )!,
      at: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}at'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      summary: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}summary'],
      )!,
    );
  }

  @override
  $JobEventsTable createAlias(String alias) {
    return $JobEventsTable(attachedDatabase, alias);
  }
}

class JobEvent extends DataClass implements Insertable<JobEvent> {
  final String id;
  final String hlc;
  final bool deleted;
  final String applicationId;
  final String at;

  /// applied | followup | reply | interview | offer | rejected | withdrawn | note
  final String kind;
  final String summary;
  const JobEvent({
    required this.id,
    required this.hlc,
    required this.deleted,
    required this.applicationId,
    required this.at,
    required this.kind,
    required this.summary,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['hlc'] = Variable<String>(hlc);
    map['deleted'] = Variable<bool>(deleted);
    map['application_id'] = Variable<String>(applicationId);
    map['at'] = Variable<String>(at);
    map['kind'] = Variable<String>(kind);
    map['summary'] = Variable<String>(summary);
    return map;
  }

  JobEventsCompanion toCompanion(bool nullToAbsent) {
    return JobEventsCompanion(
      id: Value(id),
      hlc: Value(hlc),
      deleted: Value(deleted),
      applicationId: Value(applicationId),
      at: Value(at),
      kind: Value(kind),
      summary: Value(summary),
    );
  }

  factory JobEvent.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return JobEvent(
      id: serializer.fromJson<String>(json['id']),
      hlc: serializer.fromJson<String>(json['hlc']),
      deleted: serializer.fromJson<bool>(json['deleted']),
      applicationId: serializer.fromJson<String>(json['applicationId']),
      at: serializer.fromJson<String>(json['at']),
      kind: serializer.fromJson<String>(json['kind']),
      summary: serializer.fromJson<String>(json['summary']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'hlc': serializer.toJson<String>(hlc),
      'deleted': serializer.toJson<bool>(deleted),
      'applicationId': serializer.toJson<String>(applicationId),
      'at': serializer.toJson<String>(at),
      'kind': serializer.toJson<String>(kind),
      'summary': serializer.toJson<String>(summary),
    };
  }

  JobEvent copyWith({
    String? id,
    String? hlc,
    bool? deleted,
    String? applicationId,
    String? at,
    String? kind,
    String? summary,
  }) => JobEvent(
    id: id ?? this.id,
    hlc: hlc ?? this.hlc,
    deleted: deleted ?? this.deleted,
    applicationId: applicationId ?? this.applicationId,
    at: at ?? this.at,
    kind: kind ?? this.kind,
    summary: summary ?? this.summary,
  );
  JobEvent copyWithCompanion(JobEventsCompanion data) {
    return JobEvent(
      id: data.id.present ? data.id.value : this.id,
      hlc: data.hlc.present ? data.hlc.value : this.hlc,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      applicationId: data.applicationId.present
          ? data.applicationId.value
          : this.applicationId,
      at: data.at.present ? data.at.value : this.at,
      kind: data.kind.present ? data.kind.value : this.kind,
      summary: data.summary.present ? data.summary.value : this.summary,
    );
  }

  @override
  String toString() {
    return (StringBuffer('JobEvent(')
          ..write('id: $id, ')
          ..write('hlc: $hlc, ')
          ..write('deleted: $deleted, ')
          ..write('applicationId: $applicationId, ')
          ..write('at: $at, ')
          ..write('kind: $kind, ')
          ..write('summary: $summary')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, hlc, deleted, applicationId, at, kind, summary);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is JobEvent &&
          other.id == this.id &&
          other.hlc == this.hlc &&
          other.deleted == this.deleted &&
          other.applicationId == this.applicationId &&
          other.at == this.at &&
          other.kind == this.kind &&
          other.summary == this.summary);
}

class JobEventsCompanion extends UpdateCompanion<JobEvent> {
  final Value<String> id;
  final Value<String> hlc;
  final Value<bool> deleted;
  final Value<String> applicationId;
  final Value<String> at;
  final Value<String> kind;
  final Value<String> summary;
  final Value<int> rowid;
  const JobEventsCompanion({
    this.id = const Value.absent(),
    this.hlc = const Value.absent(),
    this.deleted = const Value.absent(),
    this.applicationId = const Value.absent(),
    this.at = const Value.absent(),
    this.kind = const Value.absent(),
    this.summary = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  JobEventsCompanion.insert({
    required String id,
    this.hlc = const Value.absent(),
    this.deleted = const Value.absent(),
    required String applicationId,
    required String at,
    required String kind,
    this.summary = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       applicationId = Value(applicationId),
       at = Value(at),
       kind = Value(kind);
  static Insertable<JobEvent> custom({
    Expression<String>? id,
    Expression<String>? hlc,
    Expression<bool>? deleted,
    Expression<String>? applicationId,
    Expression<String>? at,
    Expression<String>? kind,
    Expression<String>? summary,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (hlc != null) 'hlc': hlc,
      if (deleted != null) 'deleted': deleted,
      if (applicationId != null) 'application_id': applicationId,
      if (at != null) 'at': at,
      if (kind != null) 'kind': kind,
      if (summary != null) 'summary': summary,
      if (rowid != null) 'rowid': rowid,
    });
  }

  JobEventsCompanion copyWith({
    Value<String>? id,
    Value<String>? hlc,
    Value<bool>? deleted,
    Value<String>? applicationId,
    Value<String>? at,
    Value<String>? kind,
    Value<String>? summary,
    Value<int>? rowid,
  }) {
    return JobEventsCompanion(
      id: id ?? this.id,
      hlc: hlc ?? this.hlc,
      deleted: deleted ?? this.deleted,
      applicationId: applicationId ?? this.applicationId,
      at: at ?? this.at,
      kind: kind ?? this.kind,
      summary: summary ?? this.summary,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (hlc.present) {
      map['hlc'] = Variable<String>(hlc.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (applicationId.present) {
      map['application_id'] = Variable<String>(applicationId.value);
    }
    if (at.present) {
      map['at'] = Variable<String>(at.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (summary.present) {
      map['summary'] = Variable<String>(summary.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('JobEventsCompanion(')
          ..write('id: $id, ')
          ..write('hlc: $hlc, ')
          ..write('deleted: $deleted, ')
          ..write('applicationId: $applicationId, ')
          ..write('at: $at, ')
          ..write('kind: $kind, ')
          ..write('summary: $summary, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $JobChecksTable extends JobChecks
    with TableInfo<$JobChecksTable, JobCheck> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $JobChecksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hlcMeta = const VerificationMeta('hlc');
  @override
  late final GeneratedColumn<String> hlc = GeneratedColumn<String>(
    'hlc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _deletedMeta = const VerificationMeta(
    'deleted',
  );
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _applicationIdMeta = const VerificationMeta(
    'applicationId',
  );
  @override
  late final GeneratedColumn<String> applicationId = GeneratedColumn<String>(
    'application_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('todo'),
  );
  static const VerificationMeta _dueMeta = const VerificationMeta('due');
  @override
  late final GeneratedColumn<String> due = GeneratedColumn<String>(
    'due',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _doneMeta = const VerificationMeta('done');
  @override
  late final GeneratedColumn<String> done = GeneratedColumn<String>(
    'done',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    hlc,
    deleted,
    applicationId,
    kind,
    title,
    status,
    due,
    done,
    notes,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'job_checks';
  @override
  VerificationContext validateIntegrity(
    Insertable<JobCheck> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('hlc')) {
      context.handle(
        _hlcMeta,
        hlc.isAcceptableOrUnknown(data['hlc']!, _hlcMeta),
      );
    }
    if (data.containsKey('deleted')) {
      context.handle(
        _deletedMeta,
        deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta),
      );
    }
    if (data.containsKey('application_id')) {
      context.handle(
        _applicationIdMeta,
        applicationId.isAcceptableOrUnknown(
          data['application_id']!,
          _applicationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_applicationIdMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('due')) {
      context.handle(
        _dueMeta,
        due.isAcceptableOrUnknown(data['due']!, _dueMeta),
      );
    }
    if (data.containsKey('done')) {
      context.handle(
        _doneMeta,
        done.isAcceptableOrUnknown(data['done']!, _doneMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  JobCheck map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return JobCheck(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      hlc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hlc'],
      )!,
      deleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted'],
      )!,
      applicationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}application_id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      due: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}due'],
      ),
      done: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}done'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      )!,
    );
  }

  @override
  $JobChecksTable createAlias(String alias) {
    return $JobChecksTable(attachedDatabase, alias);
  }
}

class JobCheck extends DataClass implements Insertable<JobCheck> {
  final String id;
  final String hlc;
  final bool deleted;
  final String applicationId;

  /// identity | references | criminal_record | health | qualifications |
  /// forms | contract | notice | start | other
  final String kind;
  final String title;

  /// todo | sent | done | not_needed
  final String status;
  final String? due;
  final String? done;
  final String notes;
  const JobCheck({
    required this.id,
    required this.hlc,
    required this.deleted,
    required this.applicationId,
    required this.kind,
    required this.title,
    required this.status,
    this.due,
    this.done,
    required this.notes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['hlc'] = Variable<String>(hlc);
    map['deleted'] = Variable<bool>(deleted);
    map['application_id'] = Variable<String>(applicationId);
    map['kind'] = Variable<String>(kind);
    map['title'] = Variable<String>(title);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || due != null) {
      map['due'] = Variable<String>(due);
    }
    if (!nullToAbsent || done != null) {
      map['done'] = Variable<String>(done);
    }
    map['notes'] = Variable<String>(notes);
    return map;
  }

  JobChecksCompanion toCompanion(bool nullToAbsent) {
    return JobChecksCompanion(
      id: Value(id),
      hlc: Value(hlc),
      deleted: Value(deleted),
      applicationId: Value(applicationId),
      kind: Value(kind),
      title: Value(title),
      status: Value(status),
      due: due == null && nullToAbsent ? const Value.absent() : Value(due),
      done: done == null && nullToAbsent ? const Value.absent() : Value(done),
      notes: Value(notes),
    );
  }

  factory JobCheck.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return JobCheck(
      id: serializer.fromJson<String>(json['id']),
      hlc: serializer.fromJson<String>(json['hlc']),
      deleted: serializer.fromJson<bool>(json['deleted']),
      applicationId: serializer.fromJson<String>(json['applicationId']),
      kind: serializer.fromJson<String>(json['kind']),
      title: serializer.fromJson<String>(json['title']),
      status: serializer.fromJson<String>(json['status']),
      due: serializer.fromJson<String?>(json['due']),
      done: serializer.fromJson<String?>(json['done']),
      notes: serializer.fromJson<String>(json['notes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'hlc': serializer.toJson<String>(hlc),
      'deleted': serializer.toJson<bool>(deleted),
      'applicationId': serializer.toJson<String>(applicationId),
      'kind': serializer.toJson<String>(kind),
      'title': serializer.toJson<String>(title),
      'status': serializer.toJson<String>(status),
      'due': serializer.toJson<String?>(due),
      'done': serializer.toJson<String?>(done),
      'notes': serializer.toJson<String>(notes),
    };
  }

  JobCheck copyWith({
    String? id,
    String? hlc,
    bool? deleted,
    String? applicationId,
    String? kind,
    String? title,
    String? status,
    Value<String?> due = const Value.absent(),
    Value<String?> done = const Value.absent(),
    String? notes,
  }) => JobCheck(
    id: id ?? this.id,
    hlc: hlc ?? this.hlc,
    deleted: deleted ?? this.deleted,
    applicationId: applicationId ?? this.applicationId,
    kind: kind ?? this.kind,
    title: title ?? this.title,
    status: status ?? this.status,
    due: due.present ? due.value : this.due,
    done: done.present ? done.value : this.done,
    notes: notes ?? this.notes,
  );
  JobCheck copyWithCompanion(JobChecksCompanion data) {
    return JobCheck(
      id: data.id.present ? data.id.value : this.id,
      hlc: data.hlc.present ? data.hlc.value : this.hlc,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      applicationId: data.applicationId.present
          ? data.applicationId.value
          : this.applicationId,
      kind: data.kind.present ? data.kind.value : this.kind,
      title: data.title.present ? data.title.value : this.title,
      status: data.status.present ? data.status.value : this.status,
      due: data.due.present ? data.due.value : this.due,
      done: data.done.present ? data.done.value : this.done,
      notes: data.notes.present ? data.notes.value : this.notes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('JobCheck(')
          ..write('id: $id, ')
          ..write('hlc: $hlc, ')
          ..write('deleted: $deleted, ')
          ..write('applicationId: $applicationId, ')
          ..write('kind: $kind, ')
          ..write('title: $title, ')
          ..write('status: $status, ')
          ..write('due: $due, ')
          ..write('done: $done, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    hlc,
    deleted,
    applicationId,
    kind,
    title,
    status,
    due,
    done,
    notes,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is JobCheck &&
          other.id == this.id &&
          other.hlc == this.hlc &&
          other.deleted == this.deleted &&
          other.applicationId == this.applicationId &&
          other.kind == this.kind &&
          other.title == this.title &&
          other.status == this.status &&
          other.due == this.due &&
          other.done == this.done &&
          other.notes == this.notes);
}

class JobChecksCompanion extends UpdateCompanion<JobCheck> {
  final Value<String> id;
  final Value<String> hlc;
  final Value<bool> deleted;
  final Value<String> applicationId;
  final Value<String> kind;
  final Value<String> title;
  final Value<String> status;
  final Value<String?> due;
  final Value<String?> done;
  final Value<String> notes;
  final Value<int> rowid;
  const JobChecksCompanion({
    this.id = const Value.absent(),
    this.hlc = const Value.absent(),
    this.deleted = const Value.absent(),
    this.applicationId = const Value.absent(),
    this.kind = const Value.absent(),
    this.title = const Value.absent(),
    this.status = const Value.absent(),
    this.due = const Value.absent(),
    this.done = const Value.absent(),
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  JobChecksCompanion.insert({
    required String id,
    this.hlc = const Value.absent(),
    this.deleted = const Value.absent(),
    required String applicationId,
    required String kind,
    required String title,
    this.status = const Value.absent(),
    this.due = const Value.absent(),
    this.done = const Value.absent(),
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       applicationId = Value(applicationId),
       kind = Value(kind),
       title = Value(title);
  static Insertable<JobCheck> custom({
    Expression<String>? id,
    Expression<String>? hlc,
    Expression<bool>? deleted,
    Expression<String>? applicationId,
    Expression<String>? kind,
    Expression<String>? title,
    Expression<String>? status,
    Expression<String>? due,
    Expression<String>? done,
    Expression<String>? notes,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (hlc != null) 'hlc': hlc,
      if (deleted != null) 'deleted': deleted,
      if (applicationId != null) 'application_id': applicationId,
      if (kind != null) 'kind': kind,
      if (title != null) 'title': title,
      if (status != null) 'status': status,
      if (due != null) 'due': due,
      if (done != null) 'done': done,
      if (notes != null) 'notes': notes,
      if (rowid != null) 'rowid': rowid,
    });
  }

  JobChecksCompanion copyWith({
    Value<String>? id,
    Value<String>? hlc,
    Value<bool>? deleted,
    Value<String>? applicationId,
    Value<String>? kind,
    Value<String>? title,
    Value<String>? status,
    Value<String?>? due,
    Value<String?>? done,
    Value<String>? notes,
    Value<int>? rowid,
  }) {
    return JobChecksCompanion(
      id: id ?? this.id,
      hlc: hlc ?? this.hlc,
      deleted: deleted ?? this.deleted,
      applicationId: applicationId ?? this.applicationId,
      kind: kind ?? this.kind,
      title: title ?? this.title,
      status: status ?? this.status,
      due: due ?? this.due,
      done: done ?? this.done,
      notes: notes ?? this.notes,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (hlc.present) {
      map['hlc'] = Variable<String>(hlc.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (applicationId.present) {
      map['application_id'] = Variable<String>(applicationId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (due.present) {
      map['due'] = Variable<String>(due.value);
    }
    if (done.present) {
      map['done'] = Variable<String>(done.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('JobChecksCompanion(')
          ..write('id: $id, ')
          ..write('hlc: $hlc, ')
          ..write('deleted: $deleted, ')
          ..write('applicationId: $applicationId, ')
          ..write('kind: $kind, ')
          ..write('title: $title, ')
          ..write('status: $status, ')
          ..write('due: $due, ')
          ..write('done: $done, ')
          ..write('notes: $notes, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $JobArchiveTable extends JobArchive
    with TableInfo<$JobArchiveTable, Archived> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $JobArchiveTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hlcMeta = const VerificationMeta('hlc');
  @override
  late final GeneratedColumn<String> hlc = GeneratedColumn<String>(
    'hlc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _deletedMeta = const VerificationMeta(
    'deleted',
  );
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _applicationIdMeta = const VerificationMeta(
    'applicationId',
  );
  @override
  late final GeneratedColumn<String> applicationId = GeneratedColumn<String>(
    'application_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _jobIdMeta = const VerificationMeta('jobId');
  @override
  late final GeneratedColumn<String> jobId = GeneratedColumn<String>(
    'job_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _atMeta = const VerificationMeta('at');
  @override
  late final GeneratedColumn<String> at = GeneratedColumn<String>(
    'at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
    'url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    hlc,
    deleted,
    applicationId,
    jobId,
    kind,
    at,
    title,
    url,
    content,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'job_archive';
  @override
  VerificationContext validateIntegrity(
    Insertable<Archived> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('hlc')) {
      context.handle(
        _hlcMeta,
        hlc.isAcceptableOrUnknown(data['hlc']!, _hlcMeta),
      );
    }
    if (data.containsKey('deleted')) {
      context.handle(
        _deletedMeta,
        deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta),
      );
    }
    if (data.containsKey('application_id')) {
      context.handle(
        _applicationIdMeta,
        applicationId.isAcceptableOrUnknown(
          data['application_id']!,
          _applicationIdMeta,
        ),
      );
    }
    if (data.containsKey('job_id')) {
      context.handle(
        _jobIdMeta,
        jobId.isAcceptableOrUnknown(data['job_id']!, _jobIdMeta),
      );
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('at')) {
      context.handle(_atMeta, at.isAcceptableOrUnknown(data['at']!, _atMeta));
    } else if (isInserting) {
      context.missing(_atMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('url')) {
      context.handle(
        _urlMeta,
        url.isAcceptableOrUnknown(data['url']!, _urlMeta),
      );
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Archived map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Archived(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      hlc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hlc'],
      )!,
      deleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted'],
      )!,
      applicationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}application_id'],
      ),
      jobId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}job_id'],
      ),
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      at: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}at'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      url: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}url'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
    );
  }

  @override
  $JobArchiveTable createAlias(String alias) {
    return $JobArchiveTable(attachedDatabase, alias);
  }
}

class Archived extends DataClass implements Insertable<Archived> {
  final String id;
  final String hlc;
  final bool deleted;
  final String? applicationId;
  final String? jobId;

  /// advert | application
  final String kind;
  final String at;
  final String title;
  final String url;
  final String content;
  const Archived({
    required this.id,
    required this.hlc,
    required this.deleted,
    this.applicationId,
    this.jobId,
    required this.kind,
    required this.at,
    required this.title,
    required this.url,
    required this.content,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['hlc'] = Variable<String>(hlc);
    map['deleted'] = Variable<bool>(deleted);
    if (!nullToAbsent || applicationId != null) {
      map['application_id'] = Variable<String>(applicationId);
    }
    if (!nullToAbsent || jobId != null) {
      map['job_id'] = Variable<String>(jobId);
    }
    map['kind'] = Variable<String>(kind);
    map['at'] = Variable<String>(at);
    map['title'] = Variable<String>(title);
    map['url'] = Variable<String>(url);
    map['content'] = Variable<String>(content);
    return map;
  }

  JobArchiveCompanion toCompanion(bool nullToAbsent) {
    return JobArchiveCompanion(
      id: Value(id),
      hlc: Value(hlc),
      deleted: Value(deleted),
      applicationId: applicationId == null && nullToAbsent
          ? const Value.absent()
          : Value(applicationId),
      jobId: jobId == null && nullToAbsent
          ? const Value.absent()
          : Value(jobId),
      kind: Value(kind),
      at: Value(at),
      title: Value(title),
      url: Value(url),
      content: Value(content),
    );
  }

  factory Archived.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Archived(
      id: serializer.fromJson<String>(json['id']),
      hlc: serializer.fromJson<String>(json['hlc']),
      deleted: serializer.fromJson<bool>(json['deleted']),
      applicationId: serializer.fromJson<String?>(json['applicationId']),
      jobId: serializer.fromJson<String?>(json['jobId']),
      kind: serializer.fromJson<String>(json['kind']),
      at: serializer.fromJson<String>(json['at']),
      title: serializer.fromJson<String>(json['title']),
      url: serializer.fromJson<String>(json['url']),
      content: serializer.fromJson<String>(json['content']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'hlc': serializer.toJson<String>(hlc),
      'deleted': serializer.toJson<bool>(deleted),
      'applicationId': serializer.toJson<String?>(applicationId),
      'jobId': serializer.toJson<String?>(jobId),
      'kind': serializer.toJson<String>(kind),
      'at': serializer.toJson<String>(at),
      'title': serializer.toJson<String>(title),
      'url': serializer.toJson<String>(url),
      'content': serializer.toJson<String>(content),
    };
  }

  Archived copyWith({
    String? id,
    String? hlc,
    bool? deleted,
    Value<String?> applicationId = const Value.absent(),
    Value<String?> jobId = const Value.absent(),
    String? kind,
    String? at,
    String? title,
    String? url,
    String? content,
  }) => Archived(
    id: id ?? this.id,
    hlc: hlc ?? this.hlc,
    deleted: deleted ?? this.deleted,
    applicationId: applicationId.present
        ? applicationId.value
        : this.applicationId,
    jobId: jobId.present ? jobId.value : this.jobId,
    kind: kind ?? this.kind,
    at: at ?? this.at,
    title: title ?? this.title,
    url: url ?? this.url,
    content: content ?? this.content,
  );
  Archived copyWithCompanion(JobArchiveCompanion data) {
    return Archived(
      id: data.id.present ? data.id.value : this.id,
      hlc: data.hlc.present ? data.hlc.value : this.hlc,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      applicationId: data.applicationId.present
          ? data.applicationId.value
          : this.applicationId,
      jobId: data.jobId.present ? data.jobId.value : this.jobId,
      kind: data.kind.present ? data.kind.value : this.kind,
      at: data.at.present ? data.at.value : this.at,
      title: data.title.present ? data.title.value : this.title,
      url: data.url.present ? data.url.value : this.url,
      content: data.content.present ? data.content.value : this.content,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Archived(')
          ..write('id: $id, ')
          ..write('hlc: $hlc, ')
          ..write('deleted: $deleted, ')
          ..write('applicationId: $applicationId, ')
          ..write('jobId: $jobId, ')
          ..write('kind: $kind, ')
          ..write('at: $at, ')
          ..write('title: $title, ')
          ..write('url: $url, ')
          ..write('content: $content')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    hlc,
    deleted,
    applicationId,
    jobId,
    kind,
    at,
    title,
    url,
    content,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Archived &&
          other.id == this.id &&
          other.hlc == this.hlc &&
          other.deleted == this.deleted &&
          other.applicationId == this.applicationId &&
          other.jobId == this.jobId &&
          other.kind == this.kind &&
          other.at == this.at &&
          other.title == this.title &&
          other.url == this.url &&
          other.content == this.content);
}

class JobArchiveCompanion extends UpdateCompanion<Archived> {
  final Value<String> id;
  final Value<String> hlc;
  final Value<bool> deleted;
  final Value<String?> applicationId;
  final Value<String?> jobId;
  final Value<String> kind;
  final Value<String> at;
  final Value<String> title;
  final Value<String> url;
  final Value<String> content;
  final Value<int> rowid;
  const JobArchiveCompanion({
    this.id = const Value.absent(),
    this.hlc = const Value.absent(),
    this.deleted = const Value.absent(),
    this.applicationId = const Value.absent(),
    this.jobId = const Value.absent(),
    this.kind = const Value.absent(),
    this.at = const Value.absent(),
    this.title = const Value.absent(),
    this.url = const Value.absent(),
    this.content = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  JobArchiveCompanion.insert({
    required String id,
    this.hlc = const Value.absent(),
    this.deleted = const Value.absent(),
    this.applicationId = const Value.absent(),
    this.jobId = const Value.absent(),
    required String kind,
    required String at,
    this.title = const Value.absent(),
    this.url = const Value.absent(),
    required String content,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       kind = Value(kind),
       at = Value(at),
       content = Value(content);
  static Insertable<Archived> custom({
    Expression<String>? id,
    Expression<String>? hlc,
    Expression<bool>? deleted,
    Expression<String>? applicationId,
    Expression<String>? jobId,
    Expression<String>? kind,
    Expression<String>? at,
    Expression<String>? title,
    Expression<String>? url,
    Expression<String>? content,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (hlc != null) 'hlc': hlc,
      if (deleted != null) 'deleted': deleted,
      if (applicationId != null) 'application_id': applicationId,
      if (jobId != null) 'job_id': jobId,
      if (kind != null) 'kind': kind,
      if (at != null) 'at': at,
      if (title != null) 'title': title,
      if (url != null) 'url': url,
      if (content != null) 'content': content,
      if (rowid != null) 'rowid': rowid,
    });
  }

  JobArchiveCompanion copyWith({
    Value<String>? id,
    Value<String>? hlc,
    Value<bool>? deleted,
    Value<String?>? applicationId,
    Value<String?>? jobId,
    Value<String>? kind,
    Value<String>? at,
    Value<String>? title,
    Value<String>? url,
    Value<String>? content,
    Value<int>? rowid,
  }) {
    return JobArchiveCompanion(
      id: id ?? this.id,
      hlc: hlc ?? this.hlc,
      deleted: deleted ?? this.deleted,
      applicationId: applicationId ?? this.applicationId,
      jobId: jobId ?? this.jobId,
      kind: kind ?? this.kind,
      at: at ?? this.at,
      title: title ?? this.title,
      url: url ?? this.url,
      content: content ?? this.content,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (hlc.present) {
      map['hlc'] = Variable<String>(hlc.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (applicationId.present) {
      map['application_id'] = Variable<String>(applicationId.value);
    }
    if (jobId.present) {
      map['job_id'] = Variable<String>(jobId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (at.present) {
      map['at'] = Variable<String>(at.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('JobArchiveCompanion(')
          ..write('id: $id, ')
          ..write('hlc: $hlc, ')
          ..write('deleted: $deleted, ')
          ..write('applicationId: $applicationId, ')
          ..write('jobId: $jobId, ')
          ..write('kind: $kind, ')
          ..write('at: $at, ')
          ..write('title: $title, ')
          ..write('url: $url, ')
          ..write('content: $content, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CareerContactsTable extends CareerContacts
    with TableInfo<$CareerContactsTable, Lead> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CareerContactsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hlcMeta = const VerificationMeta('hlc');
  @override
  late final GeneratedColumn<String> hlc = GeneratedColumn<String>(
    'hlc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _deletedMeta = const VerificationMeta(
    'deleted',
  );
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
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
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('recruiter'),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _companyMeta = const VerificationMeta(
    'company',
  );
  @override
  late final GeneratedColumn<String> company = GeneratedColumn<String>(
    'company',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
    'phone',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _linkedinMeta = const VerificationMeta(
    'linkedin',
  );
  @override
  late final GeneratedColumn<String> linkedin = GeneratedColumn<String>(
    'linkedin',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('new'),
  );
  static const VerificationMeta _lastContactMeta = const VerificationMeta(
    'lastContact',
  );
  @override
  late final GeneratedColumn<String> lastContact = GeneratedColumn<String>(
    'last_contact',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _followUpMeta = const VerificationMeta(
    'followUp',
  );
  @override
  late final GeneratedColumn<String> followUp = GeneratedColumn<String>(
    'follow_up',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _jobIdMeta = const VerificationMeta('jobId');
  @override
  late final GeneratedColumn<String> jobId = GeneratedColumn<String>(
    'job_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _sourceUrlMeta = const VerificationMeta(
    'sourceUrl',
  );
  @override
  late final GeneratedColumn<String> sourceUrl = GeneratedColumn<String>(
    'source_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _sourceKindMeta = const VerificationMeta(
    'sourceKind',
  );
  @override
  late final GeneratedColumn<String> sourceKind = GeneratedColumn<String>(
    'source_kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('other'),
  );
  static const VerificationMeta _foundOnMeta = const VerificationMeta(
    'foundOn',
  );
  @override
  late final GeneratedColumn<String> foundOn = GeneratedColumn<String>(
    'found_on',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _basisMeta = const VerificationMeta('basis');
  @override
  late final GeneratedColumn<String> basis = GeneratedColumn<String>(
    'basis',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('legitimate_interest'),
  );
  static const VerificationMeta _basisNoteMeta = const VerificationMeta(
    'basisNote',
  );
  @override
  late final GeneratedColumn<String> basisNote = GeneratedColumn<String>(
    'basis_note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _doNotContactMeta = const VerificationMeta(
    'doNotContact',
  );
  @override
  late final GeneratedColumn<bool> doNotContact = GeneratedColumn<bool>(
    'do_not_contact',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("do_not_contact" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _keepInTouchWeeksMeta = const VerificationMeta(
    'keepInTouchWeeks',
  );
  @override
  late final GeneratedColumn<int> keepInTouchWeeks = GeneratedColumn<int>(
    'keep_in_touch_weeks',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    hlc,
    deleted,
    name,
    kind,
    title,
    company,
    email,
    phone,
    linkedin,
    source,
    status,
    lastContact,
    followUp,
    jobId,
    notes,
    sourceUrl,
    sourceKind,
    foundOn,
    basis,
    basisNote,
    doNotContact,
    keepInTouchWeeks,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'career_contacts';
  @override
  VerificationContext validateIntegrity(
    Insertable<Lead> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('hlc')) {
      context.handle(
        _hlcMeta,
        hlc.isAcceptableOrUnknown(data['hlc']!, _hlcMeta),
      );
    }
    if (data.containsKey('deleted')) {
      context.handle(
        _deletedMeta,
        deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('company')) {
      context.handle(
        _companyMeta,
        company.isAcceptableOrUnknown(data['company']!, _companyMeta),
      );
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    }
    if (data.containsKey('phone')) {
      context.handle(
        _phoneMeta,
        phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta),
      );
    }
    if (data.containsKey('linkedin')) {
      context.handle(
        _linkedinMeta,
        linkedin.isAcceptableOrUnknown(data['linkedin']!, _linkedinMeta),
      );
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('last_contact')) {
      context.handle(
        _lastContactMeta,
        lastContact.isAcceptableOrUnknown(
          data['last_contact']!,
          _lastContactMeta,
        ),
      );
    }
    if (data.containsKey('follow_up')) {
      context.handle(
        _followUpMeta,
        followUp.isAcceptableOrUnknown(data['follow_up']!, _followUpMeta),
      );
    }
    if (data.containsKey('job_id')) {
      context.handle(
        _jobIdMeta,
        jobId.isAcceptableOrUnknown(data['job_id']!, _jobIdMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('source_url')) {
      context.handle(
        _sourceUrlMeta,
        sourceUrl.isAcceptableOrUnknown(data['source_url']!, _sourceUrlMeta),
      );
    }
    if (data.containsKey('source_kind')) {
      context.handle(
        _sourceKindMeta,
        sourceKind.isAcceptableOrUnknown(data['source_kind']!, _sourceKindMeta),
      );
    }
    if (data.containsKey('found_on')) {
      context.handle(
        _foundOnMeta,
        foundOn.isAcceptableOrUnknown(data['found_on']!, _foundOnMeta),
      );
    }
    if (data.containsKey('basis')) {
      context.handle(
        _basisMeta,
        basis.isAcceptableOrUnknown(data['basis']!, _basisMeta),
      );
    }
    if (data.containsKey('basis_note')) {
      context.handle(
        _basisNoteMeta,
        basisNote.isAcceptableOrUnknown(data['basis_note']!, _basisNoteMeta),
      );
    }
    if (data.containsKey('do_not_contact')) {
      context.handle(
        _doNotContactMeta,
        doNotContact.isAcceptableOrUnknown(
          data['do_not_contact']!,
          _doNotContactMeta,
        ),
      );
    }
    if (data.containsKey('keep_in_touch_weeks')) {
      context.handle(
        _keepInTouchWeeksMeta,
        keepInTouchWeeks.isAcceptableOrUnknown(
          data['keep_in_touch_weeks']!,
          _keepInTouchWeeksMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Lead map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Lead(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      hlc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hlc'],
      )!,
      deleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      company: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}company'],
      )!,
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      )!,
      phone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone'],
      )!,
      linkedin: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}linkedin'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      lastContact: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_contact'],
      ),
      followUp: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}follow_up'],
      ),
      jobId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}job_id'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      )!,
      sourceUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_url'],
      )!,
      sourceKind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_kind'],
      )!,
      foundOn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}found_on'],
      ),
      basis: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}basis'],
      )!,
      basisNote: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}basis_note'],
      )!,
      doNotContact: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}do_not_contact'],
      )!,
      keepInTouchWeeks: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}keep_in_touch_weeks'],
      ),
    );
  }

  @override
  $CareerContactsTable createAlias(String alias) {
    return $CareerContactsTable(attachedDatabase, alias);
  }
}

class Lead extends DataClass implements Insertable<Lead> {
  final String id;
  final String hlc;
  final bool deleted;
  final String name;

  /// recruiter | hiring_manager | referral | peer | mentor | referee | other
  final String kind;
  final String title;
  final String company;
  final String email;
  final String phone;
  final String linkedin;

  /// Where the lead was found (a team page, a job advert...).
  final String source;

  /// new | contacted | replied | cold. Since schema 4 these three follow the
  /// person's newest conversation (domain/conversations.dart); they are kept
  /// so the Contacts and Today pages read them as before.
  final String status;
  final String? lastContact;
  final String? followUp;
  final String? jobId;
  final String notes;

  /// The page the person was found on (an advert, a team page...).
  final String sourceUrl;

  /// advert | team_page | speaker | register | met | archive | inbound |
  /// referral | other
  final String sourceKind;

  /// When they were found, yyyy-MM-dd.
  final String? foundOn;

  /// legitimate_interest | they_contacted | consent
  final String basis;
  final String basisNote;

  /// True when the person asked not to be contacted: the composer is
  /// blocked and lead imports skip their address and profile.
  final bool doNotContact;

  /// "Keep in touch every N weeks", or null for no reminder.
  final int? keepInTouchWeeks;
  const Lead({
    required this.id,
    required this.hlc,
    required this.deleted,
    required this.name,
    required this.kind,
    required this.title,
    required this.company,
    required this.email,
    required this.phone,
    required this.linkedin,
    required this.source,
    required this.status,
    this.lastContact,
    this.followUp,
    this.jobId,
    required this.notes,
    required this.sourceUrl,
    required this.sourceKind,
    this.foundOn,
    required this.basis,
    required this.basisNote,
    required this.doNotContact,
    this.keepInTouchWeeks,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['hlc'] = Variable<String>(hlc);
    map['deleted'] = Variable<bool>(deleted);
    map['name'] = Variable<String>(name);
    map['kind'] = Variable<String>(kind);
    map['title'] = Variable<String>(title);
    map['company'] = Variable<String>(company);
    map['email'] = Variable<String>(email);
    map['phone'] = Variable<String>(phone);
    map['linkedin'] = Variable<String>(linkedin);
    map['source'] = Variable<String>(source);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || lastContact != null) {
      map['last_contact'] = Variable<String>(lastContact);
    }
    if (!nullToAbsent || followUp != null) {
      map['follow_up'] = Variable<String>(followUp);
    }
    if (!nullToAbsent || jobId != null) {
      map['job_id'] = Variable<String>(jobId);
    }
    map['notes'] = Variable<String>(notes);
    map['source_url'] = Variable<String>(sourceUrl);
    map['source_kind'] = Variable<String>(sourceKind);
    if (!nullToAbsent || foundOn != null) {
      map['found_on'] = Variable<String>(foundOn);
    }
    map['basis'] = Variable<String>(basis);
    map['basis_note'] = Variable<String>(basisNote);
    map['do_not_contact'] = Variable<bool>(doNotContact);
    if (!nullToAbsent || keepInTouchWeeks != null) {
      map['keep_in_touch_weeks'] = Variable<int>(keepInTouchWeeks);
    }
    return map;
  }

  CareerContactsCompanion toCompanion(bool nullToAbsent) {
    return CareerContactsCompanion(
      id: Value(id),
      hlc: Value(hlc),
      deleted: Value(deleted),
      name: Value(name),
      kind: Value(kind),
      title: Value(title),
      company: Value(company),
      email: Value(email),
      phone: Value(phone),
      linkedin: Value(linkedin),
      source: Value(source),
      status: Value(status),
      lastContact: lastContact == null && nullToAbsent
          ? const Value.absent()
          : Value(lastContact),
      followUp: followUp == null && nullToAbsent
          ? const Value.absent()
          : Value(followUp),
      jobId: jobId == null && nullToAbsent
          ? const Value.absent()
          : Value(jobId),
      notes: Value(notes),
      sourceUrl: Value(sourceUrl),
      sourceKind: Value(sourceKind),
      foundOn: foundOn == null && nullToAbsent
          ? const Value.absent()
          : Value(foundOn),
      basis: Value(basis),
      basisNote: Value(basisNote),
      doNotContact: Value(doNotContact),
      keepInTouchWeeks: keepInTouchWeeks == null && nullToAbsent
          ? const Value.absent()
          : Value(keepInTouchWeeks),
    );
  }

  factory Lead.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Lead(
      id: serializer.fromJson<String>(json['id']),
      hlc: serializer.fromJson<String>(json['hlc']),
      deleted: serializer.fromJson<bool>(json['deleted']),
      name: serializer.fromJson<String>(json['name']),
      kind: serializer.fromJson<String>(json['kind']),
      title: serializer.fromJson<String>(json['title']),
      company: serializer.fromJson<String>(json['company']),
      email: serializer.fromJson<String>(json['email']),
      phone: serializer.fromJson<String>(json['phone']),
      linkedin: serializer.fromJson<String>(json['linkedin']),
      source: serializer.fromJson<String>(json['source']),
      status: serializer.fromJson<String>(json['status']),
      lastContact: serializer.fromJson<String?>(json['lastContact']),
      followUp: serializer.fromJson<String?>(json['followUp']),
      jobId: serializer.fromJson<String?>(json['jobId']),
      notes: serializer.fromJson<String>(json['notes']),
      sourceUrl: serializer.fromJson<String>(json['sourceUrl']),
      sourceKind: serializer.fromJson<String>(json['sourceKind']),
      foundOn: serializer.fromJson<String?>(json['foundOn']),
      basis: serializer.fromJson<String>(json['basis']),
      basisNote: serializer.fromJson<String>(json['basisNote']),
      doNotContact: serializer.fromJson<bool>(json['doNotContact']),
      keepInTouchWeeks: serializer.fromJson<int?>(json['keepInTouchWeeks']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'hlc': serializer.toJson<String>(hlc),
      'deleted': serializer.toJson<bool>(deleted),
      'name': serializer.toJson<String>(name),
      'kind': serializer.toJson<String>(kind),
      'title': serializer.toJson<String>(title),
      'company': serializer.toJson<String>(company),
      'email': serializer.toJson<String>(email),
      'phone': serializer.toJson<String>(phone),
      'linkedin': serializer.toJson<String>(linkedin),
      'source': serializer.toJson<String>(source),
      'status': serializer.toJson<String>(status),
      'lastContact': serializer.toJson<String?>(lastContact),
      'followUp': serializer.toJson<String?>(followUp),
      'jobId': serializer.toJson<String?>(jobId),
      'notes': serializer.toJson<String>(notes),
      'sourceUrl': serializer.toJson<String>(sourceUrl),
      'sourceKind': serializer.toJson<String>(sourceKind),
      'foundOn': serializer.toJson<String?>(foundOn),
      'basis': serializer.toJson<String>(basis),
      'basisNote': serializer.toJson<String>(basisNote),
      'doNotContact': serializer.toJson<bool>(doNotContact),
      'keepInTouchWeeks': serializer.toJson<int?>(keepInTouchWeeks),
    };
  }

  Lead copyWith({
    String? id,
    String? hlc,
    bool? deleted,
    String? name,
    String? kind,
    String? title,
    String? company,
    String? email,
    String? phone,
    String? linkedin,
    String? source,
    String? status,
    Value<String?> lastContact = const Value.absent(),
    Value<String?> followUp = const Value.absent(),
    Value<String?> jobId = const Value.absent(),
    String? notes,
    String? sourceUrl,
    String? sourceKind,
    Value<String?> foundOn = const Value.absent(),
    String? basis,
    String? basisNote,
    bool? doNotContact,
    Value<int?> keepInTouchWeeks = const Value.absent(),
  }) => Lead(
    id: id ?? this.id,
    hlc: hlc ?? this.hlc,
    deleted: deleted ?? this.deleted,
    name: name ?? this.name,
    kind: kind ?? this.kind,
    title: title ?? this.title,
    company: company ?? this.company,
    email: email ?? this.email,
    phone: phone ?? this.phone,
    linkedin: linkedin ?? this.linkedin,
    source: source ?? this.source,
    status: status ?? this.status,
    lastContact: lastContact.present ? lastContact.value : this.lastContact,
    followUp: followUp.present ? followUp.value : this.followUp,
    jobId: jobId.present ? jobId.value : this.jobId,
    notes: notes ?? this.notes,
    sourceUrl: sourceUrl ?? this.sourceUrl,
    sourceKind: sourceKind ?? this.sourceKind,
    foundOn: foundOn.present ? foundOn.value : this.foundOn,
    basis: basis ?? this.basis,
    basisNote: basisNote ?? this.basisNote,
    doNotContact: doNotContact ?? this.doNotContact,
    keepInTouchWeeks: keepInTouchWeeks.present
        ? keepInTouchWeeks.value
        : this.keepInTouchWeeks,
  );
  Lead copyWithCompanion(CareerContactsCompanion data) {
    return Lead(
      id: data.id.present ? data.id.value : this.id,
      hlc: data.hlc.present ? data.hlc.value : this.hlc,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      name: data.name.present ? data.name.value : this.name,
      kind: data.kind.present ? data.kind.value : this.kind,
      title: data.title.present ? data.title.value : this.title,
      company: data.company.present ? data.company.value : this.company,
      email: data.email.present ? data.email.value : this.email,
      phone: data.phone.present ? data.phone.value : this.phone,
      linkedin: data.linkedin.present ? data.linkedin.value : this.linkedin,
      source: data.source.present ? data.source.value : this.source,
      status: data.status.present ? data.status.value : this.status,
      lastContact: data.lastContact.present
          ? data.lastContact.value
          : this.lastContact,
      followUp: data.followUp.present ? data.followUp.value : this.followUp,
      jobId: data.jobId.present ? data.jobId.value : this.jobId,
      notes: data.notes.present ? data.notes.value : this.notes,
      sourceUrl: data.sourceUrl.present ? data.sourceUrl.value : this.sourceUrl,
      sourceKind: data.sourceKind.present
          ? data.sourceKind.value
          : this.sourceKind,
      foundOn: data.foundOn.present ? data.foundOn.value : this.foundOn,
      basis: data.basis.present ? data.basis.value : this.basis,
      basisNote: data.basisNote.present ? data.basisNote.value : this.basisNote,
      doNotContact: data.doNotContact.present
          ? data.doNotContact.value
          : this.doNotContact,
      keepInTouchWeeks: data.keepInTouchWeeks.present
          ? data.keepInTouchWeeks.value
          : this.keepInTouchWeeks,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Lead(')
          ..write('id: $id, ')
          ..write('hlc: $hlc, ')
          ..write('deleted: $deleted, ')
          ..write('name: $name, ')
          ..write('kind: $kind, ')
          ..write('title: $title, ')
          ..write('company: $company, ')
          ..write('email: $email, ')
          ..write('phone: $phone, ')
          ..write('linkedin: $linkedin, ')
          ..write('source: $source, ')
          ..write('status: $status, ')
          ..write('lastContact: $lastContact, ')
          ..write('followUp: $followUp, ')
          ..write('jobId: $jobId, ')
          ..write('notes: $notes, ')
          ..write('sourceUrl: $sourceUrl, ')
          ..write('sourceKind: $sourceKind, ')
          ..write('foundOn: $foundOn, ')
          ..write('basis: $basis, ')
          ..write('basisNote: $basisNote, ')
          ..write('doNotContact: $doNotContact, ')
          ..write('keepInTouchWeeks: $keepInTouchWeeks')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    hlc,
    deleted,
    name,
    kind,
    title,
    company,
    email,
    phone,
    linkedin,
    source,
    status,
    lastContact,
    followUp,
    jobId,
    notes,
    sourceUrl,
    sourceKind,
    foundOn,
    basis,
    basisNote,
    doNotContact,
    keepInTouchWeeks,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Lead &&
          other.id == this.id &&
          other.hlc == this.hlc &&
          other.deleted == this.deleted &&
          other.name == this.name &&
          other.kind == this.kind &&
          other.title == this.title &&
          other.company == this.company &&
          other.email == this.email &&
          other.phone == this.phone &&
          other.linkedin == this.linkedin &&
          other.source == this.source &&
          other.status == this.status &&
          other.lastContact == this.lastContact &&
          other.followUp == this.followUp &&
          other.jobId == this.jobId &&
          other.notes == this.notes &&
          other.sourceUrl == this.sourceUrl &&
          other.sourceKind == this.sourceKind &&
          other.foundOn == this.foundOn &&
          other.basis == this.basis &&
          other.basisNote == this.basisNote &&
          other.doNotContact == this.doNotContact &&
          other.keepInTouchWeeks == this.keepInTouchWeeks);
}

class CareerContactsCompanion extends UpdateCompanion<Lead> {
  final Value<String> id;
  final Value<String> hlc;
  final Value<bool> deleted;
  final Value<String> name;
  final Value<String> kind;
  final Value<String> title;
  final Value<String> company;
  final Value<String> email;
  final Value<String> phone;
  final Value<String> linkedin;
  final Value<String> source;
  final Value<String> status;
  final Value<String?> lastContact;
  final Value<String?> followUp;
  final Value<String?> jobId;
  final Value<String> notes;
  final Value<String> sourceUrl;
  final Value<String> sourceKind;
  final Value<String?> foundOn;
  final Value<String> basis;
  final Value<String> basisNote;
  final Value<bool> doNotContact;
  final Value<int?> keepInTouchWeeks;
  final Value<int> rowid;
  const CareerContactsCompanion({
    this.id = const Value.absent(),
    this.hlc = const Value.absent(),
    this.deleted = const Value.absent(),
    this.name = const Value.absent(),
    this.kind = const Value.absent(),
    this.title = const Value.absent(),
    this.company = const Value.absent(),
    this.email = const Value.absent(),
    this.phone = const Value.absent(),
    this.linkedin = const Value.absent(),
    this.source = const Value.absent(),
    this.status = const Value.absent(),
    this.lastContact = const Value.absent(),
    this.followUp = const Value.absent(),
    this.jobId = const Value.absent(),
    this.notes = const Value.absent(),
    this.sourceUrl = const Value.absent(),
    this.sourceKind = const Value.absent(),
    this.foundOn = const Value.absent(),
    this.basis = const Value.absent(),
    this.basisNote = const Value.absent(),
    this.doNotContact = const Value.absent(),
    this.keepInTouchWeeks = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CareerContactsCompanion.insert({
    required String id,
    this.hlc = const Value.absent(),
    this.deleted = const Value.absent(),
    required String name,
    this.kind = const Value.absent(),
    this.title = const Value.absent(),
    this.company = const Value.absent(),
    this.email = const Value.absent(),
    this.phone = const Value.absent(),
    this.linkedin = const Value.absent(),
    this.source = const Value.absent(),
    this.status = const Value.absent(),
    this.lastContact = const Value.absent(),
    this.followUp = const Value.absent(),
    this.jobId = const Value.absent(),
    this.notes = const Value.absent(),
    this.sourceUrl = const Value.absent(),
    this.sourceKind = const Value.absent(),
    this.foundOn = const Value.absent(),
    this.basis = const Value.absent(),
    this.basisNote = const Value.absent(),
    this.doNotContact = const Value.absent(),
    this.keepInTouchWeeks = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name);
  static Insertable<Lead> custom({
    Expression<String>? id,
    Expression<String>? hlc,
    Expression<bool>? deleted,
    Expression<String>? name,
    Expression<String>? kind,
    Expression<String>? title,
    Expression<String>? company,
    Expression<String>? email,
    Expression<String>? phone,
    Expression<String>? linkedin,
    Expression<String>? source,
    Expression<String>? status,
    Expression<String>? lastContact,
    Expression<String>? followUp,
    Expression<String>? jobId,
    Expression<String>? notes,
    Expression<String>? sourceUrl,
    Expression<String>? sourceKind,
    Expression<String>? foundOn,
    Expression<String>? basis,
    Expression<String>? basisNote,
    Expression<bool>? doNotContact,
    Expression<int>? keepInTouchWeeks,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (hlc != null) 'hlc': hlc,
      if (deleted != null) 'deleted': deleted,
      if (name != null) 'name': name,
      if (kind != null) 'kind': kind,
      if (title != null) 'title': title,
      if (company != null) 'company': company,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      if (linkedin != null) 'linkedin': linkedin,
      if (source != null) 'source': source,
      if (status != null) 'status': status,
      if (lastContact != null) 'last_contact': lastContact,
      if (followUp != null) 'follow_up': followUp,
      if (jobId != null) 'job_id': jobId,
      if (notes != null) 'notes': notes,
      if (sourceUrl != null) 'source_url': sourceUrl,
      if (sourceKind != null) 'source_kind': sourceKind,
      if (foundOn != null) 'found_on': foundOn,
      if (basis != null) 'basis': basis,
      if (basisNote != null) 'basis_note': basisNote,
      if (doNotContact != null) 'do_not_contact': doNotContact,
      if (keepInTouchWeeks != null) 'keep_in_touch_weeks': keepInTouchWeeks,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CareerContactsCompanion copyWith({
    Value<String>? id,
    Value<String>? hlc,
    Value<bool>? deleted,
    Value<String>? name,
    Value<String>? kind,
    Value<String>? title,
    Value<String>? company,
    Value<String>? email,
    Value<String>? phone,
    Value<String>? linkedin,
    Value<String>? source,
    Value<String>? status,
    Value<String?>? lastContact,
    Value<String?>? followUp,
    Value<String?>? jobId,
    Value<String>? notes,
    Value<String>? sourceUrl,
    Value<String>? sourceKind,
    Value<String?>? foundOn,
    Value<String>? basis,
    Value<String>? basisNote,
    Value<bool>? doNotContact,
    Value<int?>? keepInTouchWeeks,
    Value<int>? rowid,
  }) {
    return CareerContactsCompanion(
      id: id ?? this.id,
      hlc: hlc ?? this.hlc,
      deleted: deleted ?? this.deleted,
      name: name ?? this.name,
      kind: kind ?? this.kind,
      title: title ?? this.title,
      company: company ?? this.company,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      linkedin: linkedin ?? this.linkedin,
      source: source ?? this.source,
      status: status ?? this.status,
      lastContact: lastContact ?? this.lastContact,
      followUp: followUp ?? this.followUp,
      jobId: jobId ?? this.jobId,
      notes: notes ?? this.notes,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      sourceKind: sourceKind ?? this.sourceKind,
      foundOn: foundOn ?? this.foundOn,
      basis: basis ?? this.basis,
      basisNote: basisNote ?? this.basisNote,
      doNotContact: doNotContact ?? this.doNotContact,
      keepInTouchWeeks: keepInTouchWeeks ?? this.keepInTouchWeeks,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (hlc.present) {
      map['hlc'] = Variable<String>(hlc.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (company.present) {
      map['company'] = Variable<String>(company.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (linkedin.present) {
      map['linkedin'] = Variable<String>(linkedin.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (lastContact.present) {
      map['last_contact'] = Variable<String>(lastContact.value);
    }
    if (followUp.present) {
      map['follow_up'] = Variable<String>(followUp.value);
    }
    if (jobId.present) {
      map['job_id'] = Variable<String>(jobId.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (sourceUrl.present) {
      map['source_url'] = Variable<String>(sourceUrl.value);
    }
    if (sourceKind.present) {
      map['source_kind'] = Variable<String>(sourceKind.value);
    }
    if (foundOn.present) {
      map['found_on'] = Variable<String>(foundOn.value);
    }
    if (basis.present) {
      map['basis'] = Variable<String>(basis.value);
    }
    if (basisNote.present) {
      map['basis_note'] = Variable<String>(basisNote.value);
    }
    if (doNotContact.present) {
      map['do_not_contact'] = Variable<bool>(doNotContact.value);
    }
    if (keepInTouchWeeks.present) {
      map['keep_in_touch_weeks'] = Variable<int>(keepInTouchWeeks.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CareerContactsCompanion(')
          ..write('id: $id, ')
          ..write('hlc: $hlc, ')
          ..write('deleted: $deleted, ')
          ..write('name: $name, ')
          ..write('kind: $kind, ')
          ..write('title: $title, ')
          ..write('company: $company, ')
          ..write('email: $email, ')
          ..write('phone: $phone, ')
          ..write('linkedin: $linkedin, ')
          ..write('source: $source, ')
          ..write('status: $status, ')
          ..write('lastContact: $lastContact, ')
          ..write('followUp: $followUp, ')
          ..write('jobId: $jobId, ')
          ..write('notes: $notes, ')
          ..write('sourceUrl: $sourceUrl, ')
          ..write('sourceKind: $sourceKind, ')
          ..write('foundOn: $foundOn, ')
          ..write('basis: $basis, ')
          ..write('basisNote: $basisNote, ')
          ..write('doNotContact: $doNotContact, ')
          ..write('keepInTouchWeeks: $keepInTouchWeeks, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CareerResumesTable extends CareerResumes
    with TableInfo<$CareerResumesTable, Resume> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CareerResumesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hlcMeta = const VerificationMeta('hlc');
  @override
  late final GeneratedColumn<String> hlc = GeneratedColumn<String>(
    'hlc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _deletedMeta = const VerificationMeta(
    'deleted',
  );
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
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
  static const VerificationMeta _jobIdMeta = const VerificationMeta('jobId');
  @override
  late final GeneratedColumn<String> jobId = GeneratedColumn<String>(
    'job_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdMeta = const VerificationMeta(
    'created',
  );
  @override
  late final GeneratedColumn<String> created = GeneratedColumn<String>(
    'created',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tailoringMeta = const VerificationMeta(
    'tailoring',
  );
  @override
  late final GeneratedColumn<String> tailoring = GeneratedColumn<String>(
    'tailoring',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    hlc,
    deleted,
    name,
    jobId,
    created,
    content,
    tailoring,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'career_resumes';
  @override
  VerificationContext validateIntegrity(
    Insertable<Resume> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('hlc')) {
      context.handle(
        _hlcMeta,
        hlc.isAcceptableOrUnknown(data['hlc']!, _hlcMeta),
      );
    }
    if (data.containsKey('deleted')) {
      context.handle(
        _deletedMeta,
        deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('job_id')) {
      context.handle(
        _jobIdMeta,
        jobId.isAcceptableOrUnknown(data['job_id']!, _jobIdMeta),
      );
    }
    if (data.containsKey('created')) {
      context.handle(
        _createdMeta,
        created.isAcceptableOrUnknown(data['created']!, _createdMeta),
      );
    } else if (isInserting) {
      context.missing(_createdMeta);
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('tailoring')) {
      context.handle(
        _tailoringMeta,
        tailoring.isAcceptableOrUnknown(data['tailoring']!, _tailoringMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Resume map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Resume(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      hlc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hlc'],
      )!,
      deleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      jobId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}job_id'],
      ),
      created: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      tailoring: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tailoring'],
      )!,
    );
  }

  @override
  $CareerResumesTable createAlias(String alias) {
    return $CareerResumesTable(attachedDatabase, alias);
  }
}

class Resume extends DataClass implements Insertable<Resume> {
  final String id;
  final String hlc;
  final bool deleted;
  final String name;
  final String? jobId;
  final String created;

  /// ResumeDoc as JSON.
  final String content;

  /// What was changed for the job, keyword cover and cautions (TailorNotes).
  final String tailoring;
  const Resume({
    required this.id,
    required this.hlc,
    required this.deleted,
    required this.name,
    this.jobId,
    required this.created,
    required this.content,
    required this.tailoring,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['hlc'] = Variable<String>(hlc);
    map['deleted'] = Variable<bool>(deleted);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || jobId != null) {
      map['job_id'] = Variable<String>(jobId);
    }
    map['created'] = Variable<String>(created);
    map['content'] = Variable<String>(content);
    map['tailoring'] = Variable<String>(tailoring);
    return map;
  }

  CareerResumesCompanion toCompanion(bool nullToAbsent) {
    return CareerResumesCompanion(
      id: Value(id),
      hlc: Value(hlc),
      deleted: Value(deleted),
      name: Value(name),
      jobId: jobId == null && nullToAbsent
          ? const Value.absent()
          : Value(jobId),
      created: Value(created),
      content: Value(content),
      tailoring: Value(tailoring),
    );
  }

  factory Resume.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Resume(
      id: serializer.fromJson<String>(json['id']),
      hlc: serializer.fromJson<String>(json['hlc']),
      deleted: serializer.fromJson<bool>(json['deleted']),
      name: serializer.fromJson<String>(json['name']),
      jobId: serializer.fromJson<String?>(json['jobId']),
      created: serializer.fromJson<String>(json['created']),
      content: serializer.fromJson<String>(json['content']),
      tailoring: serializer.fromJson<String>(json['tailoring']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'hlc': serializer.toJson<String>(hlc),
      'deleted': serializer.toJson<bool>(deleted),
      'name': serializer.toJson<String>(name),
      'jobId': serializer.toJson<String?>(jobId),
      'created': serializer.toJson<String>(created),
      'content': serializer.toJson<String>(content),
      'tailoring': serializer.toJson<String>(tailoring),
    };
  }

  Resume copyWith({
    String? id,
    String? hlc,
    bool? deleted,
    String? name,
    Value<String?> jobId = const Value.absent(),
    String? created,
    String? content,
    String? tailoring,
  }) => Resume(
    id: id ?? this.id,
    hlc: hlc ?? this.hlc,
    deleted: deleted ?? this.deleted,
    name: name ?? this.name,
    jobId: jobId.present ? jobId.value : this.jobId,
    created: created ?? this.created,
    content: content ?? this.content,
    tailoring: tailoring ?? this.tailoring,
  );
  Resume copyWithCompanion(CareerResumesCompanion data) {
    return Resume(
      id: data.id.present ? data.id.value : this.id,
      hlc: data.hlc.present ? data.hlc.value : this.hlc,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      name: data.name.present ? data.name.value : this.name,
      jobId: data.jobId.present ? data.jobId.value : this.jobId,
      created: data.created.present ? data.created.value : this.created,
      content: data.content.present ? data.content.value : this.content,
      tailoring: data.tailoring.present ? data.tailoring.value : this.tailoring,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Resume(')
          ..write('id: $id, ')
          ..write('hlc: $hlc, ')
          ..write('deleted: $deleted, ')
          ..write('name: $name, ')
          ..write('jobId: $jobId, ')
          ..write('created: $created, ')
          ..write('content: $content, ')
          ..write('tailoring: $tailoring')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, hlc, deleted, name, jobId, created, content, tailoring);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Resume &&
          other.id == this.id &&
          other.hlc == this.hlc &&
          other.deleted == this.deleted &&
          other.name == this.name &&
          other.jobId == this.jobId &&
          other.created == this.created &&
          other.content == this.content &&
          other.tailoring == this.tailoring);
}

class CareerResumesCompanion extends UpdateCompanion<Resume> {
  final Value<String> id;
  final Value<String> hlc;
  final Value<bool> deleted;
  final Value<String> name;
  final Value<String?> jobId;
  final Value<String> created;
  final Value<String> content;
  final Value<String> tailoring;
  final Value<int> rowid;
  const CareerResumesCompanion({
    this.id = const Value.absent(),
    this.hlc = const Value.absent(),
    this.deleted = const Value.absent(),
    this.name = const Value.absent(),
    this.jobId = const Value.absent(),
    this.created = const Value.absent(),
    this.content = const Value.absent(),
    this.tailoring = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CareerResumesCompanion.insert({
    required String id,
    this.hlc = const Value.absent(),
    this.deleted = const Value.absent(),
    required String name,
    this.jobId = const Value.absent(),
    required String created,
    required String content,
    this.tailoring = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       created = Value(created),
       content = Value(content);
  static Insertable<Resume> custom({
    Expression<String>? id,
    Expression<String>? hlc,
    Expression<bool>? deleted,
    Expression<String>? name,
    Expression<String>? jobId,
    Expression<String>? created,
    Expression<String>? content,
    Expression<String>? tailoring,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (hlc != null) 'hlc': hlc,
      if (deleted != null) 'deleted': deleted,
      if (name != null) 'name': name,
      if (jobId != null) 'job_id': jobId,
      if (created != null) 'created': created,
      if (content != null) 'content': content,
      if (tailoring != null) 'tailoring': tailoring,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CareerResumesCompanion copyWith({
    Value<String>? id,
    Value<String>? hlc,
    Value<bool>? deleted,
    Value<String>? name,
    Value<String?>? jobId,
    Value<String>? created,
    Value<String>? content,
    Value<String>? tailoring,
    Value<int>? rowid,
  }) {
    return CareerResumesCompanion(
      id: id ?? this.id,
      hlc: hlc ?? this.hlc,
      deleted: deleted ?? this.deleted,
      name: name ?? this.name,
      jobId: jobId ?? this.jobId,
      created: created ?? this.created,
      content: content ?? this.content,
      tailoring: tailoring ?? this.tailoring,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (hlc.present) {
      map['hlc'] = Variable<String>(hlc.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (jobId.present) {
      map['job_id'] = Variable<String>(jobId.value);
    }
    if (created.present) {
      map['created'] = Variable<String>(created.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (tailoring.present) {
      map['tailoring'] = Variable<String>(tailoring.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CareerResumesCompanion(')
          ..write('id: $id, ')
          ..write('hlc: $hlc, ')
          ..write('deleted: $deleted, ')
          ..write('name: $name, ')
          ..write('jobId: $jobId, ')
          ..write('created: $created, ')
          ..write('content: $content, ')
          ..write('tailoring: $tailoring, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CareerReportsTable extends CareerReports
    with TableInfo<$CareerReportsTable, Report> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CareerReportsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hlcMeta = const VerificationMeta('hlc');
  @override
  late final GeneratedColumn<String> hlc = GeneratedColumn<String>(
    'hlc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _deletedMeta = const VerificationMeta(
    'deleted',
  );
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdMeta = const VerificationMeta(
    'created',
  );
  @override
  late final GeneratedColumn<String> created = GeneratedColumn<String>(
    'created',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourcesMeta = const VerificationMeta(
    'sources',
  );
  @override
  late final GeneratedColumn<String> sources = GeneratedColumn<String>(
    'sources',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    hlc,
    deleted,
    kind,
    created,
    content,
    sources,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'career_reports';
  @override
  VerificationContext validateIntegrity(
    Insertable<Report> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('hlc')) {
      context.handle(
        _hlcMeta,
        hlc.isAcceptableOrUnknown(data['hlc']!, _hlcMeta),
      );
    }
    if (data.containsKey('deleted')) {
      context.handle(
        _deletedMeta,
        deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta),
      );
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('created')) {
      context.handle(
        _createdMeta,
        created.isAcceptableOrUnknown(data['created']!, _createdMeta),
      );
    } else if (isInserting) {
      context.missing(_createdMeta);
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('sources')) {
      context.handle(
        _sourcesMeta,
        sources.isAcceptableOrUnknown(data['sources']!, _sourcesMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Report map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Report(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      hlc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hlc'],
      )!,
      deleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      created: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      sources: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sources'],
      )!,
    );
  }

  @override
  $CareerReportsTable createAlias(String alias) {
    return $CareerReportsTable(attachedDatabase, alias);
  }
}

class Report extends DataClass implements Insertable<Report> {
  final String id;
  final String hlc;
  final bool deleted;

  /// assessment | career_map
  final String kind;
  final String created;
  final String content;

  /// Web pages the AI read for it, as JSON [{title, url}].
  final String sources;
  const Report({
    required this.id,
    required this.hlc,
    required this.deleted,
    required this.kind,
    required this.created,
    required this.content,
    required this.sources,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['hlc'] = Variable<String>(hlc);
    map['deleted'] = Variable<bool>(deleted);
    map['kind'] = Variable<String>(kind);
    map['created'] = Variable<String>(created);
    map['content'] = Variable<String>(content);
    map['sources'] = Variable<String>(sources);
    return map;
  }

  CareerReportsCompanion toCompanion(bool nullToAbsent) {
    return CareerReportsCompanion(
      id: Value(id),
      hlc: Value(hlc),
      deleted: Value(deleted),
      kind: Value(kind),
      created: Value(created),
      content: Value(content),
      sources: Value(sources),
    );
  }

  factory Report.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Report(
      id: serializer.fromJson<String>(json['id']),
      hlc: serializer.fromJson<String>(json['hlc']),
      deleted: serializer.fromJson<bool>(json['deleted']),
      kind: serializer.fromJson<String>(json['kind']),
      created: serializer.fromJson<String>(json['created']),
      content: serializer.fromJson<String>(json['content']),
      sources: serializer.fromJson<String>(json['sources']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'hlc': serializer.toJson<String>(hlc),
      'deleted': serializer.toJson<bool>(deleted),
      'kind': serializer.toJson<String>(kind),
      'created': serializer.toJson<String>(created),
      'content': serializer.toJson<String>(content),
      'sources': serializer.toJson<String>(sources),
    };
  }

  Report copyWith({
    String? id,
    String? hlc,
    bool? deleted,
    String? kind,
    String? created,
    String? content,
    String? sources,
  }) => Report(
    id: id ?? this.id,
    hlc: hlc ?? this.hlc,
    deleted: deleted ?? this.deleted,
    kind: kind ?? this.kind,
    created: created ?? this.created,
    content: content ?? this.content,
    sources: sources ?? this.sources,
  );
  Report copyWithCompanion(CareerReportsCompanion data) {
    return Report(
      id: data.id.present ? data.id.value : this.id,
      hlc: data.hlc.present ? data.hlc.value : this.hlc,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      kind: data.kind.present ? data.kind.value : this.kind,
      created: data.created.present ? data.created.value : this.created,
      content: data.content.present ? data.content.value : this.content,
      sources: data.sources.present ? data.sources.value : this.sources,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Report(')
          ..write('id: $id, ')
          ..write('hlc: $hlc, ')
          ..write('deleted: $deleted, ')
          ..write('kind: $kind, ')
          ..write('created: $created, ')
          ..write('content: $content, ')
          ..write('sources: $sources')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, hlc, deleted, kind, created, content, sources);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Report &&
          other.id == this.id &&
          other.hlc == this.hlc &&
          other.deleted == this.deleted &&
          other.kind == this.kind &&
          other.created == this.created &&
          other.content == this.content &&
          other.sources == this.sources);
}

class CareerReportsCompanion extends UpdateCompanion<Report> {
  final Value<String> id;
  final Value<String> hlc;
  final Value<bool> deleted;
  final Value<String> kind;
  final Value<String> created;
  final Value<String> content;
  final Value<String> sources;
  final Value<int> rowid;
  const CareerReportsCompanion({
    this.id = const Value.absent(),
    this.hlc = const Value.absent(),
    this.deleted = const Value.absent(),
    this.kind = const Value.absent(),
    this.created = const Value.absent(),
    this.content = const Value.absent(),
    this.sources = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CareerReportsCompanion.insert({
    required String id,
    this.hlc = const Value.absent(),
    this.deleted = const Value.absent(),
    required String kind,
    required String created,
    required String content,
    this.sources = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       kind = Value(kind),
       created = Value(created),
       content = Value(content);
  static Insertable<Report> custom({
    Expression<String>? id,
    Expression<String>? hlc,
    Expression<bool>? deleted,
    Expression<String>? kind,
    Expression<String>? created,
    Expression<String>? content,
    Expression<String>? sources,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (hlc != null) 'hlc': hlc,
      if (deleted != null) 'deleted': deleted,
      if (kind != null) 'kind': kind,
      if (created != null) 'created': created,
      if (content != null) 'content': content,
      if (sources != null) 'sources': sources,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CareerReportsCompanion copyWith({
    Value<String>? id,
    Value<String>? hlc,
    Value<bool>? deleted,
    Value<String>? kind,
    Value<String>? created,
    Value<String>? content,
    Value<String>? sources,
    Value<int>? rowid,
  }) {
    return CareerReportsCompanion(
      id: id ?? this.id,
      hlc: hlc ?? this.hlc,
      deleted: deleted ?? this.deleted,
      kind: kind ?? this.kind,
      created: created ?? this.created,
      content: content ?? this.content,
      sources: sources ?? this.sources,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (hlc.present) {
      map['hlc'] = Variable<String>(hlc.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (created.present) {
      map['created'] = Variable<String>(created.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (sources.present) {
      map['sources'] = Variable<String>(sources.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CareerReportsCompanion(')
          ..write('id: $id, ')
          ..write('hlc: $hlc, ')
          ..write('deleted: $deleted, ')
          ..write('kind: $kind, ')
          ..write('created: $created, ')
          ..write('content: $content, ')
          ..write('sources: $sources, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CareerGrowthTable extends CareerGrowth
    with TableInfo<$CareerGrowthTable, GrowthItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CareerGrowthTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hlcMeta = const VerificationMeta('hlc');
  @override
  late final GeneratedColumn<String> hlc = GeneratedColumn<String>(
    'hlc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _deletedMeta = const VerificationMeta(
    'deleted',
  );
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _providerMeta = const VerificationMeta(
    'provider',
  );
  @override
  late final GeneratedColumn<String> provider = GeneratedColumn<String>(
    'provider',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
    'url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _whyMeta = const VerificationMeta('why');
  @override
  late final GeneratedColumn<String> why = GeneratedColumn<String>(
    'why',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _costMeta = const VerificationMeta('cost');
  @override
  late final GeneratedColumn<String> cost = GeneratedColumn<String>(
    'cost',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _durationMeta = const VerificationMeta(
    'duration',
  );
  @override
  late final GeneratedColumn<String> duration = GeneratedColumn<String>(
    'duration',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('suggested'),
  );
  static const VerificationMeta _progressMeta = const VerificationMeta(
    'progress',
  );
  @override
  late final GeneratedColumn<int> progress = GeneratedColumn<int>(
    'progress',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _targetMeta = const VerificationMeta('target');
  @override
  late final GeneratedColumn<String> target = GeneratedColumn<String>(
    'target',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _doneMeta = const VerificationMeta('done');
  @override
  late final GeneratedColumn<String> done = GeneratedColumn<String>(
    'done',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pathMeta = const VerificationMeta('path');
  @override
  late final GeneratedColumn<String> path = GeneratedColumn<String>(
    'path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _addedMeta = const VerificationMeta('added');
  @override
  late final GeneratedColumn<String> added = GeneratedColumn<String>(
    'added',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    hlc,
    deleted,
    title,
    kind,
    provider,
    url,
    why,
    cost,
    duration,
    status,
    progress,
    target,
    done,
    path,
    added,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'career_growth';
  @override
  VerificationContext validateIntegrity(
    Insertable<GrowthItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('hlc')) {
      context.handle(
        _hlcMeta,
        hlc.isAcceptableOrUnknown(data['hlc']!, _hlcMeta),
      );
    }
    if (data.containsKey('deleted')) {
      context.handle(
        _deletedMeta,
        deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('provider')) {
      context.handle(
        _providerMeta,
        provider.isAcceptableOrUnknown(data['provider']!, _providerMeta),
      );
    }
    if (data.containsKey('url')) {
      context.handle(
        _urlMeta,
        url.isAcceptableOrUnknown(data['url']!, _urlMeta),
      );
    }
    if (data.containsKey('why')) {
      context.handle(
        _whyMeta,
        why.isAcceptableOrUnknown(data['why']!, _whyMeta),
      );
    }
    if (data.containsKey('cost')) {
      context.handle(
        _costMeta,
        cost.isAcceptableOrUnknown(data['cost']!, _costMeta),
      );
    }
    if (data.containsKey('duration')) {
      context.handle(
        _durationMeta,
        duration.isAcceptableOrUnknown(data['duration']!, _durationMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('progress')) {
      context.handle(
        _progressMeta,
        progress.isAcceptableOrUnknown(data['progress']!, _progressMeta),
      );
    }
    if (data.containsKey('target')) {
      context.handle(
        _targetMeta,
        target.isAcceptableOrUnknown(data['target']!, _targetMeta),
      );
    }
    if (data.containsKey('done')) {
      context.handle(
        _doneMeta,
        done.isAcceptableOrUnknown(data['done']!, _doneMeta),
      );
    }
    if (data.containsKey('path')) {
      context.handle(
        _pathMeta,
        path.isAcceptableOrUnknown(data['path']!, _pathMeta),
      );
    }
    if (data.containsKey('added')) {
      context.handle(
        _addedMeta,
        added.isAcceptableOrUnknown(data['added']!, _addedMeta),
      );
    } else if (isInserting) {
      context.missing(_addedMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GrowthItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GrowthItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      hlc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hlc'],
      )!,
      deleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      provider: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provider'],
      )!,
      url: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}url'],
      )!,
      why: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}why'],
      )!,
      cost: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cost'],
      )!,
      duration: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}duration'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      progress: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}progress'],
      )!,
      target: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target'],
      ),
      done: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}done'],
      ),
      path: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}path'],
      )!,
      added: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}added'],
      )!,
    );
  }

  @override
  $CareerGrowthTable createAlias(String alias) {
    return $CareerGrowthTable(attachedDatabase, alias);
  }
}

class GrowthItem extends DataClass implements Insertable<GrowthItem> {
  final String id;
  final String hlc;
  final bool deleted;
  final String title;

  /// certification | course | degree | skill | experience | goal
  final String kind;
  final String provider;
  final String url;
  final String why;
  final String cost;
  final String duration;

  /// suggested | planned | doing | done | dropped
  final String status;

  /// 0 to 100.
  final int progress;
  final String? target;
  final String? done;

  /// The career path it serves, by name, when it came from the map.
  final String path;
  final String added;
  const GrowthItem({
    required this.id,
    required this.hlc,
    required this.deleted,
    required this.title,
    required this.kind,
    required this.provider,
    required this.url,
    required this.why,
    required this.cost,
    required this.duration,
    required this.status,
    required this.progress,
    this.target,
    this.done,
    required this.path,
    required this.added,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['hlc'] = Variable<String>(hlc);
    map['deleted'] = Variable<bool>(deleted);
    map['title'] = Variable<String>(title);
    map['kind'] = Variable<String>(kind);
    map['provider'] = Variable<String>(provider);
    map['url'] = Variable<String>(url);
    map['why'] = Variable<String>(why);
    map['cost'] = Variable<String>(cost);
    map['duration'] = Variable<String>(duration);
    map['status'] = Variable<String>(status);
    map['progress'] = Variable<int>(progress);
    if (!nullToAbsent || target != null) {
      map['target'] = Variable<String>(target);
    }
    if (!nullToAbsent || done != null) {
      map['done'] = Variable<String>(done);
    }
    map['path'] = Variable<String>(path);
    map['added'] = Variable<String>(added);
    return map;
  }

  CareerGrowthCompanion toCompanion(bool nullToAbsent) {
    return CareerGrowthCompanion(
      id: Value(id),
      hlc: Value(hlc),
      deleted: Value(deleted),
      title: Value(title),
      kind: Value(kind),
      provider: Value(provider),
      url: Value(url),
      why: Value(why),
      cost: Value(cost),
      duration: Value(duration),
      status: Value(status),
      progress: Value(progress),
      target: target == null && nullToAbsent
          ? const Value.absent()
          : Value(target),
      done: done == null && nullToAbsent ? const Value.absent() : Value(done),
      path: Value(path),
      added: Value(added),
    );
  }

  factory GrowthItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GrowthItem(
      id: serializer.fromJson<String>(json['id']),
      hlc: serializer.fromJson<String>(json['hlc']),
      deleted: serializer.fromJson<bool>(json['deleted']),
      title: serializer.fromJson<String>(json['title']),
      kind: serializer.fromJson<String>(json['kind']),
      provider: serializer.fromJson<String>(json['provider']),
      url: serializer.fromJson<String>(json['url']),
      why: serializer.fromJson<String>(json['why']),
      cost: serializer.fromJson<String>(json['cost']),
      duration: serializer.fromJson<String>(json['duration']),
      status: serializer.fromJson<String>(json['status']),
      progress: serializer.fromJson<int>(json['progress']),
      target: serializer.fromJson<String?>(json['target']),
      done: serializer.fromJson<String?>(json['done']),
      path: serializer.fromJson<String>(json['path']),
      added: serializer.fromJson<String>(json['added']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'hlc': serializer.toJson<String>(hlc),
      'deleted': serializer.toJson<bool>(deleted),
      'title': serializer.toJson<String>(title),
      'kind': serializer.toJson<String>(kind),
      'provider': serializer.toJson<String>(provider),
      'url': serializer.toJson<String>(url),
      'why': serializer.toJson<String>(why),
      'cost': serializer.toJson<String>(cost),
      'duration': serializer.toJson<String>(duration),
      'status': serializer.toJson<String>(status),
      'progress': serializer.toJson<int>(progress),
      'target': serializer.toJson<String?>(target),
      'done': serializer.toJson<String?>(done),
      'path': serializer.toJson<String>(path),
      'added': serializer.toJson<String>(added),
    };
  }

  GrowthItem copyWith({
    String? id,
    String? hlc,
    bool? deleted,
    String? title,
    String? kind,
    String? provider,
    String? url,
    String? why,
    String? cost,
    String? duration,
    String? status,
    int? progress,
    Value<String?> target = const Value.absent(),
    Value<String?> done = const Value.absent(),
    String? path,
    String? added,
  }) => GrowthItem(
    id: id ?? this.id,
    hlc: hlc ?? this.hlc,
    deleted: deleted ?? this.deleted,
    title: title ?? this.title,
    kind: kind ?? this.kind,
    provider: provider ?? this.provider,
    url: url ?? this.url,
    why: why ?? this.why,
    cost: cost ?? this.cost,
    duration: duration ?? this.duration,
    status: status ?? this.status,
    progress: progress ?? this.progress,
    target: target.present ? target.value : this.target,
    done: done.present ? done.value : this.done,
    path: path ?? this.path,
    added: added ?? this.added,
  );
  GrowthItem copyWithCompanion(CareerGrowthCompanion data) {
    return GrowthItem(
      id: data.id.present ? data.id.value : this.id,
      hlc: data.hlc.present ? data.hlc.value : this.hlc,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      title: data.title.present ? data.title.value : this.title,
      kind: data.kind.present ? data.kind.value : this.kind,
      provider: data.provider.present ? data.provider.value : this.provider,
      url: data.url.present ? data.url.value : this.url,
      why: data.why.present ? data.why.value : this.why,
      cost: data.cost.present ? data.cost.value : this.cost,
      duration: data.duration.present ? data.duration.value : this.duration,
      status: data.status.present ? data.status.value : this.status,
      progress: data.progress.present ? data.progress.value : this.progress,
      target: data.target.present ? data.target.value : this.target,
      done: data.done.present ? data.done.value : this.done,
      path: data.path.present ? data.path.value : this.path,
      added: data.added.present ? data.added.value : this.added,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GrowthItem(')
          ..write('id: $id, ')
          ..write('hlc: $hlc, ')
          ..write('deleted: $deleted, ')
          ..write('title: $title, ')
          ..write('kind: $kind, ')
          ..write('provider: $provider, ')
          ..write('url: $url, ')
          ..write('why: $why, ')
          ..write('cost: $cost, ')
          ..write('duration: $duration, ')
          ..write('status: $status, ')
          ..write('progress: $progress, ')
          ..write('target: $target, ')
          ..write('done: $done, ')
          ..write('path: $path, ')
          ..write('added: $added')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    hlc,
    deleted,
    title,
    kind,
    provider,
    url,
    why,
    cost,
    duration,
    status,
    progress,
    target,
    done,
    path,
    added,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GrowthItem &&
          other.id == this.id &&
          other.hlc == this.hlc &&
          other.deleted == this.deleted &&
          other.title == this.title &&
          other.kind == this.kind &&
          other.provider == this.provider &&
          other.url == this.url &&
          other.why == this.why &&
          other.cost == this.cost &&
          other.duration == this.duration &&
          other.status == this.status &&
          other.progress == this.progress &&
          other.target == this.target &&
          other.done == this.done &&
          other.path == this.path &&
          other.added == this.added);
}

class CareerGrowthCompanion extends UpdateCompanion<GrowthItem> {
  final Value<String> id;
  final Value<String> hlc;
  final Value<bool> deleted;
  final Value<String> title;
  final Value<String> kind;
  final Value<String> provider;
  final Value<String> url;
  final Value<String> why;
  final Value<String> cost;
  final Value<String> duration;
  final Value<String> status;
  final Value<int> progress;
  final Value<String?> target;
  final Value<String?> done;
  final Value<String> path;
  final Value<String> added;
  final Value<int> rowid;
  const CareerGrowthCompanion({
    this.id = const Value.absent(),
    this.hlc = const Value.absent(),
    this.deleted = const Value.absent(),
    this.title = const Value.absent(),
    this.kind = const Value.absent(),
    this.provider = const Value.absent(),
    this.url = const Value.absent(),
    this.why = const Value.absent(),
    this.cost = const Value.absent(),
    this.duration = const Value.absent(),
    this.status = const Value.absent(),
    this.progress = const Value.absent(),
    this.target = const Value.absent(),
    this.done = const Value.absent(),
    this.path = const Value.absent(),
    this.added = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CareerGrowthCompanion.insert({
    required String id,
    this.hlc = const Value.absent(),
    this.deleted = const Value.absent(),
    required String title,
    required String kind,
    this.provider = const Value.absent(),
    this.url = const Value.absent(),
    this.why = const Value.absent(),
    this.cost = const Value.absent(),
    this.duration = const Value.absent(),
    this.status = const Value.absent(),
    this.progress = const Value.absent(),
    this.target = const Value.absent(),
    this.done = const Value.absent(),
    this.path = const Value.absent(),
    required String added,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       kind = Value(kind),
       added = Value(added);
  static Insertable<GrowthItem> custom({
    Expression<String>? id,
    Expression<String>? hlc,
    Expression<bool>? deleted,
    Expression<String>? title,
    Expression<String>? kind,
    Expression<String>? provider,
    Expression<String>? url,
    Expression<String>? why,
    Expression<String>? cost,
    Expression<String>? duration,
    Expression<String>? status,
    Expression<int>? progress,
    Expression<String>? target,
    Expression<String>? done,
    Expression<String>? path,
    Expression<String>? added,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (hlc != null) 'hlc': hlc,
      if (deleted != null) 'deleted': deleted,
      if (title != null) 'title': title,
      if (kind != null) 'kind': kind,
      if (provider != null) 'provider': provider,
      if (url != null) 'url': url,
      if (why != null) 'why': why,
      if (cost != null) 'cost': cost,
      if (duration != null) 'duration': duration,
      if (status != null) 'status': status,
      if (progress != null) 'progress': progress,
      if (target != null) 'target': target,
      if (done != null) 'done': done,
      if (path != null) 'path': path,
      if (added != null) 'added': added,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CareerGrowthCompanion copyWith({
    Value<String>? id,
    Value<String>? hlc,
    Value<bool>? deleted,
    Value<String>? title,
    Value<String>? kind,
    Value<String>? provider,
    Value<String>? url,
    Value<String>? why,
    Value<String>? cost,
    Value<String>? duration,
    Value<String>? status,
    Value<int>? progress,
    Value<String?>? target,
    Value<String?>? done,
    Value<String>? path,
    Value<String>? added,
    Value<int>? rowid,
  }) {
    return CareerGrowthCompanion(
      id: id ?? this.id,
      hlc: hlc ?? this.hlc,
      deleted: deleted ?? this.deleted,
      title: title ?? this.title,
      kind: kind ?? this.kind,
      provider: provider ?? this.provider,
      url: url ?? this.url,
      why: why ?? this.why,
      cost: cost ?? this.cost,
      duration: duration ?? this.duration,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      target: target ?? this.target,
      done: done ?? this.done,
      path: path ?? this.path,
      added: added ?? this.added,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (hlc.present) {
      map['hlc'] = Variable<String>(hlc.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (provider.present) {
      map['provider'] = Variable<String>(provider.value);
    }
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (why.present) {
      map['why'] = Variable<String>(why.value);
    }
    if (cost.present) {
      map['cost'] = Variable<String>(cost.value);
    }
    if (duration.present) {
      map['duration'] = Variable<String>(duration.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (progress.present) {
      map['progress'] = Variable<int>(progress.value);
    }
    if (target.present) {
      map['target'] = Variable<String>(target.value);
    }
    if (done.present) {
      map['done'] = Variable<String>(done.value);
    }
    if (path.present) {
      map['path'] = Variable<String>(path.value);
    }
    if (added.present) {
      map['added'] = Variable<String>(added.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CareerGrowthCompanion(')
          ..write('id: $id, ')
          ..write('hlc: $hlc, ')
          ..write('deleted: $deleted, ')
          ..write('title: $title, ')
          ..write('kind: $kind, ')
          ..write('provider: $provider, ')
          ..write('url: $url, ')
          ..write('why: $why, ')
          ..write('cost: $cost, ')
          ..write('duration: $duration, ')
          ..write('status: $status, ')
          ..write('progress: $progress, ')
          ..write('target: $target, ')
          ..write('done: $done, ')
          ..write('path: $path, ')
          ..write('added: $added, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CareerPracticeTable extends CareerPractice
    with TableInfo<$CareerPracticeTable, PracticeSession> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CareerPracticeTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hlcMeta = const VerificationMeta('hlc');
  @override
  late final GeneratedColumn<String> hlc = GeneratedColumn<String>(
    'hlc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _deletedMeta = const VerificationMeta(
    'deleted',
  );
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _jobIdMeta = const VerificationMeta('jobId');
  @override
  late final GeneratedColumn<String> jobId = GeneratedColumn<String>(
    'job_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _modeMeta = const VerificationMeta('mode');
  @override
  late final GeneratedColumn<String> mode = GeneratedColumn<String>(
    'mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startedMeta = const VerificationMeta(
    'started',
  );
  @override
  late final GeneratedColumn<String> started = GeneratedColumn<String>(
    'started',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _questionsMeta = const VerificationMeta(
    'questions',
  );
  @override
  late final GeneratedColumn<String> questions = GeneratedColumn<String>(
    'questions',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scoreMeta = const VerificationMeta('score');
  @override
  late final GeneratedColumn<double> score = GeneratedColumn<double>(
    'score',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _profileIdMeta = const VerificationMeta(
    'profileId',
  );
  @override
  late final GeneratedColumn<String> profileId = GeneratedColumn<String>(
    'profile_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _debriefMeta = const VerificationMeta(
    'debrief',
  );
  @override
  late final GeneratedColumn<String> debrief = GeneratedColumn<String>(
    'debrief',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _nervesBeforeMeta = const VerificationMeta(
    'nervesBefore',
  );
  @override
  late final GeneratedColumn<int> nervesBefore = GeneratedColumn<int>(
    'nerves_before',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nervesAfterMeta = const VerificationMeta(
    'nervesAfter',
  );
  @override
  late final GeneratedColumn<int> nervesAfter = GeneratedColumn<int>(
    'nerves_after',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    hlc,
    deleted,
    jobId,
    role,
    mode,
    started,
    questions,
    score,
    profileId,
    debrief,
    nervesBefore,
    nervesAfter,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'career_practice';
  @override
  VerificationContext validateIntegrity(
    Insertable<PracticeSession> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('hlc')) {
      context.handle(
        _hlcMeta,
        hlc.isAcceptableOrUnknown(data['hlc']!, _hlcMeta),
      );
    }
    if (data.containsKey('deleted')) {
      context.handle(
        _deletedMeta,
        deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta),
      );
    }
    if (data.containsKey('job_id')) {
      context.handle(
        _jobIdMeta,
        jobId.isAcceptableOrUnknown(data['job_id']!, _jobIdMeta),
      );
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('mode')) {
      context.handle(
        _modeMeta,
        mode.isAcceptableOrUnknown(data['mode']!, _modeMeta),
      );
    } else if (isInserting) {
      context.missing(_modeMeta);
    }
    if (data.containsKey('started')) {
      context.handle(
        _startedMeta,
        started.isAcceptableOrUnknown(data['started']!, _startedMeta),
      );
    } else if (isInserting) {
      context.missing(_startedMeta);
    }
    if (data.containsKey('questions')) {
      context.handle(
        _questionsMeta,
        questions.isAcceptableOrUnknown(data['questions']!, _questionsMeta),
      );
    } else if (isInserting) {
      context.missing(_questionsMeta);
    }
    if (data.containsKey('score')) {
      context.handle(
        _scoreMeta,
        score.isAcceptableOrUnknown(data['score']!, _scoreMeta),
      );
    }
    if (data.containsKey('profile_id')) {
      context.handle(
        _profileIdMeta,
        profileId.isAcceptableOrUnknown(data['profile_id']!, _profileIdMeta),
      );
    }
    if (data.containsKey('debrief')) {
      context.handle(
        _debriefMeta,
        debrief.isAcceptableOrUnknown(data['debrief']!, _debriefMeta),
      );
    }
    if (data.containsKey('nerves_before')) {
      context.handle(
        _nervesBeforeMeta,
        nervesBefore.isAcceptableOrUnknown(
          data['nerves_before']!,
          _nervesBeforeMeta,
        ),
      );
    }
    if (data.containsKey('nerves_after')) {
      context.handle(
        _nervesAfterMeta,
        nervesAfter.isAcceptableOrUnknown(
          data['nerves_after']!,
          _nervesAfterMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PracticeSession map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PracticeSession(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      hlc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hlc'],
      )!,
      deleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted'],
      )!,
      jobId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}job_id'],
      ),
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      )!,
      mode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mode'],
      )!,
      started: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}started'],
      )!,
      questions: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}questions'],
      )!,
      score: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}score'],
      ),
      profileId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}profile_id'],
      ),
      debrief: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}debrief'],
      )!,
      nervesBefore: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}nerves_before'],
      ),
      nervesAfter: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}nerves_after'],
      ),
    );
  }

  @override
  $CareerPracticeTable createAlias(String alias) {
    return $CareerPracticeTable(attachedDatabase, alias);
  }
}

class PracticeSession extends DataClass implements Insertable<PracticeSession> {
  final String id;
  final String hlc;
  final bool deleted;
  final String? jobId;
  final String role;

  /// standard | competency | technical | toughest | ai
  final String mode;
  final String started;

  /// The question set (PracticeQuestion list as JSON).
  final String questions;

  /// Mean of the scored answers, 0 to 10.
  final double? score;

  /// The role profile (career_role_profiles) the round's questions came
  /// from, if any.
  final String? profileId;

  /// The panel scoring of the round (interview plan I3) as JSON: the
  /// framework and each answer's scores with the quotes they rest on, ''
  /// until scored. Text only, like the transcripts.
  final String debrief;

  /// How nervous the candidate felt before and after the round, 1 (calm)
  /// to 5 (very nervous), when they said (interview plan I4).
  final int? nervesBefore;
  final int? nervesAfter;
  const PracticeSession({
    required this.id,
    required this.hlc,
    required this.deleted,
    this.jobId,
    required this.role,
    required this.mode,
    required this.started,
    required this.questions,
    this.score,
    this.profileId,
    required this.debrief,
    this.nervesBefore,
    this.nervesAfter,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['hlc'] = Variable<String>(hlc);
    map['deleted'] = Variable<bool>(deleted);
    if (!nullToAbsent || jobId != null) {
      map['job_id'] = Variable<String>(jobId);
    }
    map['role'] = Variable<String>(role);
    map['mode'] = Variable<String>(mode);
    map['started'] = Variable<String>(started);
    map['questions'] = Variable<String>(questions);
    if (!nullToAbsent || score != null) {
      map['score'] = Variable<double>(score);
    }
    if (!nullToAbsent || profileId != null) {
      map['profile_id'] = Variable<String>(profileId);
    }
    map['debrief'] = Variable<String>(debrief);
    if (!nullToAbsent || nervesBefore != null) {
      map['nerves_before'] = Variable<int>(nervesBefore);
    }
    if (!nullToAbsent || nervesAfter != null) {
      map['nerves_after'] = Variable<int>(nervesAfter);
    }
    return map;
  }

  CareerPracticeCompanion toCompanion(bool nullToAbsent) {
    return CareerPracticeCompanion(
      id: Value(id),
      hlc: Value(hlc),
      deleted: Value(deleted),
      jobId: jobId == null && nullToAbsent
          ? const Value.absent()
          : Value(jobId),
      role: Value(role),
      mode: Value(mode),
      started: Value(started),
      questions: Value(questions),
      score: score == null && nullToAbsent
          ? const Value.absent()
          : Value(score),
      profileId: profileId == null && nullToAbsent
          ? const Value.absent()
          : Value(profileId),
      debrief: Value(debrief),
      nervesBefore: nervesBefore == null && nullToAbsent
          ? const Value.absent()
          : Value(nervesBefore),
      nervesAfter: nervesAfter == null && nullToAbsent
          ? const Value.absent()
          : Value(nervesAfter),
    );
  }

  factory PracticeSession.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PracticeSession(
      id: serializer.fromJson<String>(json['id']),
      hlc: serializer.fromJson<String>(json['hlc']),
      deleted: serializer.fromJson<bool>(json['deleted']),
      jobId: serializer.fromJson<String?>(json['jobId']),
      role: serializer.fromJson<String>(json['role']),
      mode: serializer.fromJson<String>(json['mode']),
      started: serializer.fromJson<String>(json['started']),
      questions: serializer.fromJson<String>(json['questions']),
      score: serializer.fromJson<double?>(json['score']),
      profileId: serializer.fromJson<String?>(json['profileId']),
      debrief: serializer.fromJson<String>(json['debrief']),
      nervesBefore: serializer.fromJson<int?>(json['nervesBefore']),
      nervesAfter: serializer.fromJson<int?>(json['nervesAfter']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'hlc': serializer.toJson<String>(hlc),
      'deleted': serializer.toJson<bool>(deleted),
      'jobId': serializer.toJson<String?>(jobId),
      'role': serializer.toJson<String>(role),
      'mode': serializer.toJson<String>(mode),
      'started': serializer.toJson<String>(started),
      'questions': serializer.toJson<String>(questions),
      'score': serializer.toJson<double?>(score),
      'profileId': serializer.toJson<String?>(profileId),
      'debrief': serializer.toJson<String>(debrief),
      'nervesBefore': serializer.toJson<int?>(nervesBefore),
      'nervesAfter': serializer.toJson<int?>(nervesAfter),
    };
  }

  PracticeSession copyWith({
    String? id,
    String? hlc,
    bool? deleted,
    Value<String?> jobId = const Value.absent(),
    String? role,
    String? mode,
    String? started,
    String? questions,
    Value<double?> score = const Value.absent(),
    Value<String?> profileId = const Value.absent(),
    String? debrief,
    Value<int?> nervesBefore = const Value.absent(),
    Value<int?> nervesAfter = const Value.absent(),
  }) => PracticeSession(
    id: id ?? this.id,
    hlc: hlc ?? this.hlc,
    deleted: deleted ?? this.deleted,
    jobId: jobId.present ? jobId.value : this.jobId,
    role: role ?? this.role,
    mode: mode ?? this.mode,
    started: started ?? this.started,
    questions: questions ?? this.questions,
    score: score.present ? score.value : this.score,
    profileId: profileId.present ? profileId.value : this.profileId,
    debrief: debrief ?? this.debrief,
    nervesBefore: nervesBefore.present ? nervesBefore.value : this.nervesBefore,
    nervesAfter: nervesAfter.present ? nervesAfter.value : this.nervesAfter,
  );
  PracticeSession copyWithCompanion(CareerPracticeCompanion data) {
    return PracticeSession(
      id: data.id.present ? data.id.value : this.id,
      hlc: data.hlc.present ? data.hlc.value : this.hlc,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      jobId: data.jobId.present ? data.jobId.value : this.jobId,
      role: data.role.present ? data.role.value : this.role,
      mode: data.mode.present ? data.mode.value : this.mode,
      started: data.started.present ? data.started.value : this.started,
      questions: data.questions.present ? data.questions.value : this.questions,
      score: data.score.present ? data.score.value : this.score,
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      debrief: data.debrief.present ? data.debrief.value : this.debrief,
      nervesBefore: data.nervesBefore.present
          ? data.nervesBefore.value
          : this.nervesBefore,
      nervesAfter: data.nervesAfter.present
          ? data.nervesAfter.value
          : this.nervesAfter,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PracticeSession(')
          ..write('id: $id, ')
          ..write('hlc: $hlc, ')
          ..write('deleted: $deleted, ')
          ..write('jobId: $jobId, ')
          ..write('role: $role, ')
          ..write('mode: $mode, ')
          ..write('started: $started, ')
          ..write('questions: $questions, ')
          ..write('score: $score, ')
          ..write('profileId: $profileId, ')
          ..write('debrief: $debrief, ')
          ..write('nervesBefore: $nervesBefore, ')
          ..write('nervesAfter: $nervesAfter')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    hlc,
    deleted,
    jobId,
    role,
    mode,
    started,
    questions,
    score,
    profileId,
    debrief,
    nervesBefore,
    nervesAfter,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PracticeSession &&
          other.id == this.id &&
          other.hlc == this.hlc &&
          other.deleted == this.deleted &&
          other.jobId == this.jobId &&
          other.role == this.role &&
          other.mode == this.mode &&
          other.started == this.started &&
          other.questions == this.questions &&
          other.score == this.score &&
          other.profileId == this.profileId &&
          other.debrief == this.debrief &&
          other.nervesBefore == this.nervesBefore &&
          other.nervesAfter == this.nervesAfter);
}

class CareerPracticeCompanion extends UpdateCompanion<PracticeSession> {
  final Value<String> id;
  final Value<String> hlc;
  final Value<bool> deleted;
  final Value<String?> jobId;
  final Value<String> role;
  final Value<String> mode;
  final Value<String> started;
  final Value<String> questions;
  final Value<double?> score;
  final Value<String?> profileId;
  final Value<String> debrief;
  final Value<int?> nervesBefore;
  final Value<int?> nervesAfter;
  final Value<int> rowid;
  const CareerPracticeCompanion({
    this.id = const Value.absent(),
    this.hlc = const Value.absent(),
    this.deleted = const Value.absent(),
    this.jobId = const Value.absent(),
    this.role = const Value.absent(),
    this.mode = const Value.absent(),
    this.started = const Value.absent(),
    this.questions = const Value.absent(),
    this.score = const Value.absent(),
    this.profileId = const Value.absent(),
    this.debrief = const Value.absent(),
    this.nervesBefore = const Value.absent(),
    this.nervesAfter = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CareerPracticeCompanion.insert({
    required String id,
    this.hlc = const Value.absent(),
    this.deleted = const Value.absent(),
    this.jobId = const Value.absent(),
    required String role,
    required String mode,
    required String started,
    required String questions,
    this.score = const Value.absent(),
    this.profileId = const Value.absent(),
    this.debrief = const Value.absent(),
    this.nervesBefore = const Value.absent(),
    this.nervesAfter = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       role = Value(role),
       mode = Value(mode),
       started = Value(started),
       questions = Value(questions);
  static Insertable<PracticeSession> custom({
    Expression<String>? id,
    Expression<String>? hlc,
    Expression<bool>? deleted,
    Expression<String>? jobId,
    Expression<String>? role,
    Expression<String>? mode,
    Expression<String>? started,
    Expression<String>? questions,
    Expression<double>? score,
    Expression<String>? profileId,
    Expression<String>? debrief,
    Expression<int>? nervesBefore,
    Expression<int>? nervesAfter,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (hlc != null) 'hlc': hlc,
      if (deleted != null) 'deleted': deleted,
      if (jobId != null) 'job_id': jobId,
      if (role != null) 'role': role,
      if (mode != null) 'mode': mode,
      if (started != null) 'started': started,
      if (questions != null) 'questions': questions,
      if (score != null) 'score': score,
      if (profileId != null) 'profile_id': profileId,
      if (debrief != null) 'debrief': debrief,
      if (nervesBefore != null) 'nerves_before': nervesBefore,
      if (nervesAfter != null) 'nerves_after': nervesAfter,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CareerPracticeCompanion copyWith({
    Value<String>? id,
    Value<String>? hlc,
    Value<bool>? deleted,
    Value<String?>? jobId,
    Value<String>? role,
    Value<String>? mode,
    Value<String>? started,
    Value<String>? questions,
    Value<double?>? score,
    Value<String?>? profileId,
    Value<String>? debrief,
    Value<int?>? nervesBefore,
    Value<int?>? nervesAfter,
    Value<int>? rowid,
  }) {
    return CareerPracticeCompanion(
      id: id ?? this.id,
      hlc: hlc ?? this.hlc,
      deleted: deleted ?? this.deleted,
      jobId: jobId ?? this.jobId,
      role: role ?? this.role,
      mode: mode ?? this.mode,
      started: started ?? this.started,
      questions: questions ?? this.questions,
      score: score ?? this.score,
      profileId: profileId ?? this.profileId,
      debrief: debrief ?? this.debrief,
      nervesBefore: nervesBefore ?? this.nervesBefore,
      nervesAfter: nervesAfter ?? this.nervesAfter,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (hlc.present) {
      map['hlc'] = Variable<String>(hlc.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (jobId.present) {
      map['job_id'] = Variable<String>(jobId.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (mode.present) {
      map['mode'] = Variable<String>(mode.value);
    }
    if (started.present) {
      map['started'] = Variable<String>(started.value);
    }
    if (questions.present) {
      map['questions'] = Variable<String>(questions.value);
    }
    if (score.present) {
      map['score'] = Variable<double>(score.value);
    }
    if (profileId.present) {
      map['profile_id'] = Variable<String>(profileId.value);
    }
    if (debrief.present) {
      map['debrief'] = Variable<String>(debrief.value);
    }
    if (nervesBefore.present) {
      map['nerves_before'] = Variable<int>(nervesBefore.value);
    }
    if (nervesAfter.present) {
      map['nerves_after'] = Variable<int>(nervesAfter.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CareerPracticeCompanion(')
          ..write('id: $id, ')
          ..write('hlc: $hlc, ')
          ..write('deleted: $deleted, ')
          ..write('jobId: $jobId, ')
          ..write('role: $role, ')
          ..write('mode: $mode, ')
          ..write('started: $started, ')
          ..write('questions: $questions, ')
          ..write('score: $score, ')
          ..write('profileId: $profileId, ')
          ..write('debrief: $debrief, ')
          ..write('nervesBefore: $nervesBefore, ')
          ..write('nervesAfter: $nervesAfter, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CareerAnswersTable extends CareerAnswers
    with TableInfo<$CareerAnswersTable, PracticeAnswer> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CareerAnswersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hlcMeta = const VerificationMeta('hlc');
  @override
  late final GeneratedColumn<String> hlc = GeneratedColumn<String>(
    'hlc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _deletedMeta = const VerificationMeta(
    'deleted',
  );
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _questionMeta = const VerificationMeta(
    'question',
  );
  @override
  late final GeneratedColumn<int> question = GeneratedColumn<int>(
    'question',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _answerMeta = const VerificationMeta('answer');
  @override
  late final GeneratedColumn<String> answer = GeneratedColumn<String>(
    'answer',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _atMeta = const VerificationMeta('at');
  @override
  late final GeneratedColumn<String> at = GeneratedColumn<String>(
    'at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reviewMeta = const VerificationMeta('review');
  @override
  late final GeneratedColumn<String> review = GeneratedColumn<String>(
    'review',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _scoreMeta = const VerificationMeta('score');
  @override
  late final GeneratedColumn<double> score = GeneratedColumn<double>(
    'score',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    hlc,
    deleted,
    sessionId,
    question,
    answer,
    at,
    review,
    score,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'career_answers';
  @override
  VerificationContext validateIntegrity(
    Insertable<PracticeAnswer> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('hlc')) {
      context.handle(
        _hlcMeta,
        hlc.isAcceptableOrUnknown(data['hlc']!, _hlcMeta),
      );
    }
    if (data.containsKey('deleted')) {
      context.handle(
        _deletedMeta,
        deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta),
      );
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('question')) {
      context.handle(
        _questionMeta,
        question.isAcceptableOrUnknown(data['question']!, _questionMeta),
      );
    } else if (isInserting) {
      context.missing(_questionMeta);
    }
    if (data.containsKey('answer')) {
      context.handle(
        _answerMeta,
        answer.isAcceptableOrUnknown(data['answer']!, _answerMeta),
      );
    } else if (isInserting) {
      context.missing(_answerMeta);
    }
    if (data.containsKey('at')) {
      context.handle(_atMeta, at.isAcceptableOrUnknown(data['at']!, _atMeta));
    } else if (isInserting) {
      context.missing(_atMeta);
    }
    if (data.containsKey('review')) {
      context.handle(
        _reviewMeta,
        review.isAcceptableOrUnknown(data['review']!, _reviewMeta),
      );
    }
    if (data.containsKey('score')) {
      context.handle(
        _scoreMeta,
        score.isAcceptableOrUnknown(data['score']!, _scoreMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PracticeAnswer map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PracticeAnswer(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      hlc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hlc'],
      )!,
      deleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      question: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}question'],
      )!,
      answer: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}answer'],
      )!,
      at: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}at'],
      )!,
      review: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}review'],
      )!,
      score: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}score'],
      ),
    );
  }

  @override
  $CareerAnswersTable createAlias(String alias) {
    return $CareerAnswersTable(attachedDatabase, alias);
  }
}

class PracticeAnswer extends DataClass implements Insertable<PracticeAnswer> {
  final String id;
  final String hlc;
  final bool deleted;
  final String sessionId;
  final int question;
  final String answer;
  final String at;

  /// AnswerReview as JSON, '' until evaluated.
  final String review;
  final double? score;
  const PracticeAnswer({
    required this.id,
    required this.hlc,
    required this.deleted,
    required this.sessionId,
    required this.question,
    required this.answer,
    required this.at,
    required this.review,
    this.score,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['hlc'] = Variable<String>(hlc);
    map['deleted'] = Variable<bool>(deleted);
    map['session_id'] = Variable<String>(sessionId);
    map['question'] = Variable<int>(question);
    map['answer'] = Variable<String>(answer);
    map['at'] = Variable<String>(at);
    map['review'] = Variable<String>(review);
    if (!nullToAbsent || score != null) {
      map['score'] = Variable<double>(score);
    }
    return map;
  }

  CareerAnswersCompanion toCompanion(bool nullToAbsent) {
    return CareerAnswersCompanion(
      id: Value(id),
      hlc: Value(hlc),
      deleted: Value(deleted),
      sessionId: Value(sessionId),
      question: Value(question),
      answer: Value(answer),
      at: Value(at),
      review: Value(review),
      score: score == null && nullToAbsent
          ? const Value.absent()
          : Value(score),
    );
  }

  factory PracticeAnswer.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PracticeAnswer(
      id: serializer.fromJson<String>(json['id']),
      hlc: serializer.fromJson<String>(json['hlc']),
      deleted: serializer.fromJson<bool>(json['deleted']),
      sessionId: serializer.fromJson<String>(json['sessionId']),
      question: serializer.fromJson<int>(json['question']),
      answer: serializer.fromJson<String>(json['answer']),
      at: serializer.fromJson<String>(json['at']),
      review: serializer.fromJson<String>(json['review']),
      score: serializer.fromJson<double?>(json['score']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'hlc': serializer.toJson<String>(hlc),
      'deleted': serializer.toJson<bool>(deleted),
      'sessionId': serializer.toJson<String>(sessionId),
      'question': serializer.toJson<int>(question),
      'answer': serializer.toJson<String>(answer),
      'at': serializer.toJson<String>(at),
      'review': serializer.toJson<String>(review),
      'score': serializer.toJson<double?>(score),
    };
  }

  PracticeAnswer copyWith({
    String? id,
    String? hlc,
    bool? deleted,
    String? sessionId,
    int? question,
    String? answer,
    String? at,
    String? review,
    Value<double?> score = const Value.absent(),
  }) => PracticeAnswer(
    id: id ?? this.id,
    hlc: hlc ?? this.hlc,
    deleted: deleted ?? this.deleted,
    sessionId: sessionId ?? this.sessionId,
    question: question ?? this.question,
    answer: answer ?? this.answer,
    at: at ?? this.at,
    review: review ?? this.review,
    score: score.present ? score.value : this.score,
  );
  PracticeAnswer copyWithCompanion(CareerAnswersCompanion data) {
    return PracticeAnswer(
      id: data.id.present ? data.id.value : this.id,
      hlc: data.hlc.present ? data.hlc.value : this.hlc,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      question: data.question.present ? data.question.value : this.question,
      answer: data.answer.present ? data.answer.value : this.answer,
      at: data.at.present ? data.at.value : this.at,
      review: data.review.present ? data.review.value : this.review,
      score: data.score.present ? data.score.value : this.score,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PracticeAnswer(')
          ..write('id: $id, ')
          ..write('hlc: $hlc, ')
          ..write('deleted: $deleted, ')
          ..write('sessionId: $sessionId, ')
          ..write('question: $question, ')
          ..write('answer: $answer, ')
          ..write('at: $at, ')
          ..write('review: $review, ')
          ..write('score: $score')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    hlc,
    deleted,
    sessionId,
    question,
    answer,
    at,
    review,
    score,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PracticeAnswer &&
          other.id == this.id &&
          other.hlc == this.hlc &&
          other.deleted == this.deleted &&
          other.sessionId == this.sessionId &&
          other.question == this.question &&
          other.answer == this.answer &&
          other.at == this.at &&
          other.review == this.review &&
          other.score == this.score);
}

class CareerAnswersCompanion extends UpdateCompanion<PracticeAnswer> {
  final Value<String> id;
  final Value<String> hlc;
  final Value<bool> deleted;
  final Value<String> sessionId;
  final Value<int> question;
  final Value<String> answer;
  final Value<String> at;
  final Value<String> review;
  final Value<double?> score;
  final Value<int> rowid;
  const CareerAnswersCompanion({
    this.id = const Value.absent(),
    this.hlc = const Value.absent(),
    this.deleted = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.question = const Value.absent(),
    this.answer = const Value.absent(),
    this.at = const Value.absent(),
    this.review = const Value.absent(),
    this.score = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CareerAnswersCompanion.insert({
    required String id,
    this.hlc = const Value.absent(),
    this.deleted = const Value.absent(),
    required String sessionId,
    required int question,
    required String answer,
    required String at,
    this.review = const Value.absent(),
    this.score = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sessionId = Value(sessionId),
       question = Value(question),
       answer = Value(answer),
       at = Value(at);
  static Insertable<PracticeAnswer> custom({
    Expression<String>? id,
    Expression<String>? hlc,
    Expression<bool>? deleted,
    Expression<String>? sessionId,
    Expression<int>? question,
    Expression<String>? answer,
    Expression<String>? at,
    Expression<String>? review,
    Expression<double>? score,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (hlc != null) 'hlc': hlc,
      if (deleted != null) 'deleted': deleted,
      if (sessionId != null) 'session_id': sessionId,
      if (question != null) 'question': question,
      if (answer != null) 'answer': answer,
      if (at != null) 'at': at,
      if (review != null) 'review': review,
      if (score != null) 'score': score,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CareerAnswersCompanion copyWith({
    Value<String>? id,
    Value<String>? hlc,
    Value<bool>? deleted,
    Value<String>? sessionId,
    Value<int>? question,
    Value<String>? answer,
    Value<String>? at,
    Value<String>? review,
    Value<double?>? score,
    Value<int>? rowid,
  }) {
    return CareerAnswersCompanion(
      id: id ?? this.id,
      hlc: hlc ?? this.hlc,
      deleted: deleted ?? this.deleted,
      sessionId: sessionId ?? this.sessionId,
      question: question ?? this.question,
      answer: answer ?? this.answer,
      at: at ?? this.at,
      review: review ?? this.review,
      score: score ?? this.score,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (hlc.present) {
      map['hlc'] = Variable<String>(hlc.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (question.present) {
      map['question'] = Variable<int>(question.value);
    }
    if (answer.present) {
      map['answer'] = Variable<String>(answer.value);
    }
    if (at.present) {
      map['at'] = Variable<String>(at.value);
    }
    if (review.present) {
      map['review'] = Variable<String>(review.value);
    }
    if (score.present) {
      map['score'] = Variable<double>(score.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CareerAnswersCompanion(')
          ..write('id: $id, ')
          ..write('hlc: $hlc, ')
          ..write('deleted: $deleted, ')
          ..write('sessionId: $sessionId, ')
          ..write('question: $question, ')
          ..write('answer: $answer, ')
          ..write('at: $at, ')
          ..write('review: $review, ')
          ..write('score: $score, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CareerDocumentsTable extends CareerDocuments
    with TableInfo<$CareerDocumentsTable, CareerDocument> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CareerDocumentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hlcMeta = const VerificationMeta('hlc');
  @override
  late final GeneratedColumn<String> hlc = GeneratedColumn<String>(
    'hlc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _deletedMeta = const VerificationMeta(
    'deleted',
  );
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _hashMeta = const VerificationMeta('hash');
  @override
  late final GeneratedColumn<String> hash = GeneratedColumn<String>(
    'hash',
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
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('other'),
  );
  static const VerificationMeta _summaryMeta = const VerificationMeta(
    'summary',
  );
  @override
  late final GeneratedColumn<String> summary = GeneratedColumn<String>(
    'summary',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _factsMeta = const VerificationMeta('facts');
  @override
  late final GeneratedColumn<String> facts = GeneratedColumn<String>(
    'facts',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _foundMeta = const VerificationMeta('found');
  @override
  late final GeneratedColumn<String> found = GeneratedColumn<String>(
    'found',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _analysedMeta = const VerificationMeta(
    'analysed',
  );
  @override
  late final GeneratedColumn<String> analysed = GeneratedColumn<String>(
    'analysed',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _useMeta = const VerificationMeta('use');
  @override
  late final GeneratedColumn<bool> use = GeneratedColumn<bool>(
    'use',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("use" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    hlc,
    deleted,
    hash,
    name,
    kind,
    summary,
    facts,
    content,
    found,
    analysed,
    use,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'career_documents';
  @override
  VerificationContext validateIntegrity(
    Insertable<CareerDocument> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('hlc')) {
      context.handle(
        _hlcMeta,
        hlc.isAcceptableOrUnknown(data['hlc']!, _hlcMeta),
      );
    }
    if (data.containsKey('deleted')) {
      context.handle(
        _deletedMeta,
        deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta),
      );
    }
    if (data.containsKey('hash')) {
      context.handle(
        _hashMeta,
        hash.isAcceptableOrUnknown(data['hash']!, _hashMeta),
      );
    } else if (isInserting) {
      context.missing(_hashMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    }
    if (data.containsKey('summary')) {
      context.handle(
        _summaryMeta,
        summary.isAcceptableOrUnknown(data['summary']!, _summaryMeta),
      );
    }
    if (data.containsKey('facts')) {
      context.handle(
        _factsMeta,
        facts.isAcceptableOrUnknown(data['facts']!, _factsMeta),
      );
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    }
    if (data.containsKey('found')) {
      context.handle(
        _foundMeta,
        found.isAcceptableOrUnknown(data['found']!, _foundMeta),
      );
    } else if (isInserting) {
      context.missing(_foundMeta);
    }
    if (data.containsKey('analysed')) {
      context.handle(
        _analysedMeta,
        analysed.isAcceptableOrUnknown(data['analysed']!, _analysedMeta),
      );
    }
    if (data.containsKey('use')) {
      context.handle(
        _useMeta,
        use.isAcceptableOrUnknown(data['use']!, _useMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CareerDocument map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CareerDocument(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      hlc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hlc'],
      )!,
      deleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted'],
      )!,
      hash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hash'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      summary: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}summary'],
      )!,
      facts: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}facts'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      found: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}found'],
      )!,
      analysed: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}analysed'],
      ),
      use: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}use'],
      )!,
    );
  }

  @override
  $CareerDocumentsTable createAlias(String alias) {
    return $CareerDocumentsTable(attachedDatabase, alias);
  }
}

class CareerDocument extends DataClass implements Insertable<CareerDocument> {
  final String id;
  final String hlc;
  final bool deleted;

  /// SHA-256 of the file's bytes, hex.
  final String hash;
  final String name;

  /// cv | reference | interview | advert | application | certificate |
  /// notes | other (see domain/companion.dart).
  final String kind;
  final String summary;

  /// DocumentReading.facts as JSON.
  final String facts;

  /// The text read from the file (Word, text, Markdown); '' for PDFs,
  /// which the AI reads whole.
  final String content;
  final String found;

  /// When the AI read it; null until then.
  final String? analysed;

  /// False when the candidate asked Udyoga to ignore it.
  final bool use;
  const CareerDocument({
    required this.id,
    required this.hlc,
    required this.deleted,
    required this.hash,
    required this.name,
    required this.kind,
    required this.summary,
    required this.facts,
    required this.content,
    required this.found,
    this.analysed,
    required this.use,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['hlc'] = Variable<String>(hlc);
    map['deleted'] = Variable<bool>(deleted);
    map['hash'] = Variable<String>(hash);
    map['name'] = Variable<String>(name);
    map['kind'] = Variable<String>(kind);
    map['summary'] = Variable<String>(summary);
    map['facts'] = Variable<String>(facts);
    map['content'] = Variable<String>(content);
    map['found'] = Variable<String>(found);
    if (!nullToAbsent || analysed != null) {
      map['analysed'] = Variable<String>(analysed);
    }
    map['use'] = Variable<bool>(use);
    return map;
  }

  CareerDocumentsCompanion toCompanion(bool nullToAbsent) {
    return CareerDocumentsCompanion(
      id: Value(id),
      hlc: Value(hlc),
      deleted: Value(deleted),
      hash: Value(hash),
      name: Value(name),
      kind: Value(kind),
      summary: Value(summary),
      facts: Value(facts),
      content: Value(content),
      found: Value(found),
      analysed: analysed == null && nullToAbsent
          ? const Value.absent()
          : Value(analysed),
      use: Value(use),
    );
  }

  factory CareerDocument.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CareerDocument(
      id: serializer.fromJson<String>(json['id']),
      hlc: serializer.fromJson<String>(json['hlc']),
      deleted: serializer.fromJson<bool>(json['deleted']),
      hash: serializer.fromJson<String>(json['hash']),
      name: serializer.fromJson<String>(json['name']),
      kind: serializer.fromJson<String>(json['kind']),
      summary: serializer.fromJson<String>(json['summary']),
      facts: serializer.fromJson<String>(json['facts']),
      content: serializer.fromJson<String>(json['content']),
      found: serializer.fromJson<String>(json['found']),
      analysed: serializer.fromJson<String?>(json['analysed']),
      use: serializer.fromJson<bool>(json['use']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'hlc': serializer.toJson<String>(hlc),
      'deleted': serializer.toJson<bool>(deleted),
      'hash': serializer.toJson<String>(hash),
      'name': serializer.toJson<String>(name),
      'kind': serializer.toJson<String>(kind),
      'summary': serializer.toJson<String>(summary),
      'facts': serializer.toJson<String>(facts),
      'content': serializer.toJson<String>(content),
      'found': serializer.toJson<String>(found),
      'analysed': serializer.toJson<String?>(analysed),
      'use': serializer.toJson<bool>(use),
    };
  }

  CareerDocument copyWith({
    String? id,
    String? hlc,
    bool? deleted,
    String? hash,
    String? name,
    String? kind,
    String? summary,
    String? facts,
    String? content,
    String? found,
    Value<String?> analysed = const Value.absent(),
    bool? use,
  }) => CareerDocument(
    id: id ?? this.id,
    hlc: hlc ?? this.hlc,
    deleted: deleted ?? this.deleted,
    hash: hash ?? this.hash,
    name: name ?? this.name,
    kind: kind ?? this.kind,
    summary: summary ?? this.summary,
    facts: facts ?? this.facts,
    content: content ?? this.content,
    found: found ?? this.found,
    analysed: analysed.present ? analysed.value : this.analysed,
    use: use ?? this.use,
  );
  CareerDocument copyWithCompanion(CareerDocumentsCompanion data) {
    return CareerDocument(
      id: data.id.present ? data.id.value : this.id,
      hlc: data.hlc.present ? data.hlc.value : this.hlc,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      hash: data.hash.present ? data.hash.value : this.hash,
      name: data.name.present ? data.name.value : this.name,
      kind: data.kind.present ? data.kind.value : this.kind,
      summary: data.summary.present ? data.summary.value : this.summary,
      facts: data.facts.present ? data.facts.value : this.facts,
      content: data.content.present ? data.content.value : this.content,
      found: data.found.present ? data.found.value : this.found,
      analysed: data.analysed.present ? data.analysed.value : this.analysed,
      use: data.use.present ? data.use.value : this.use,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CareerDocument(')
          ..write('id: $id, ')
          ..write('hlc: $hlc, ')
          ..write('deleted: $deleted, ')
          ..write('hash: $hash, ')
          ..write('name: $name, ')
          ..write('kind: $kind, ')
          ..write('summary: $summary, ')
          ..write('facts: $facts, ')
          ..write('content: $content, ')
          ..write('found: $found, ')
          ..write('analysed: $analysed, ')
          ..write('use: $use')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    hlc,
    deleted,
    hash,
    name,
    kind,
    summary,
    facts,
    content,
    found,
    analysed,
    use,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CareerDocument &&
          other.id == this.id &&
          other.hlc == this.hlc &&
          other.deleted == this.deleted &&
          other.hash == this.hash &&
          other.name == this.name &&
          other.kind == this.kind &&
          other.summary == this.summary &&
          other.facts == this.facts &&
          other.content == this.content &&
          other.found == this.found &&
          other.analysed == this.analysed &&
          other.use == this.use);
}

class CareerDocumentsCompanion extends UpdateCompanion<CareerDocument> {
  final Value<String> id;
  final Value<String> hlc;
  final Value<bool> deleted;
  final Value<String> hash;
  final Value<String> name;
  final Value<String> kind;
  final Value<String> summary;
  final Value<String> facts;
  final Value<String> content;
  final Value<String> found;
  final Value<String?> analysed;
  final Value<bool> use;
  final Value<int> rowid;
  const CareerDocumentsCompanion({
    this.id = const Value.absent(),
    this.hlc = const Value.absent(),
    this.deleted = const Value.absent(),
    this.hash = const Value.absent(),
    this.name = const Value.absent(),
    this.kind = const Value.absent(),
    this.summary = const Value.absent(),
    this.facts = const Value.absent(),
    this.content = const Value.absent(),
    this.found = const Value.absent(),
    this.analysed = const Value.absent(),
    this.use = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CareerDocumentsCompanion.insert({
    required String id,
    this.hlc = const Value.absent(),
    this.deleted = const Value.absent(),
    required String hash,
    required String name,
    this.kind = const Value.absent(),
    this.summary = const Value.absent(),
    this.facts = const Value.absent(),
    this.content = const Value.absent(),
    required String found,
    this.analysed = const Value.absent(),
    this.use = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       hash = Value(hash),
       name = Value(name),
       found = Value(found);
  static Insertable<CareerDocument> custom({
    Expression<String>? id,
    Expression<String>? hlc,
    Expression<bool>? deleted,
    Expression<String>? hash,
    Expression<String>? name,
    Expression<String>? kind,
    Expression<String>? summary,
    Expression<String>? facts,
    Expression<String>? content,
    Expression<String>? found,
    Expression<String>? analysed,
    Expression<bool>? use,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (hlc != null) 'hlc': hlc,
      if (deleted != null) 'deleted': deleted,
      if (hash != null) 'hash': hash,
      if (name != null) 'name': name,
      if (kind != null) 'kind': kind,
      if (summary != null) 'summary': summary,
      if (facts != null) 'facts': facts,
      if (content != null) 'content': content,
      if (found != null) 'found': found,
      if (analysed != null) 'analysed': analysed,
      if (use != null) 'use': use,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CareerDocumentsCompanion copyWith({
    Value<String>? id,
    Value<String>? hlc,
    Value<bool>? deleted,
    Value<String>? hash,
    Value<String>? name,
    Value<String>? kind,
    Value<String>? summary,
    Value<String>? facts,
    Value<String>? content,
    Value<String>? found,
    Value<String?>? analysed,
    Value<bool>? use,
    Value<int>? rowid,
  }) {
    return CareerDocumentsCompanion(
      id: id ?? this.id,
      hlc: hlc ?? this.hlc,
      deleted: deleted ?? this.deleted,
      hash: hash ?? this.hash,
      name: name ?? this.name,
      kind: kind ?? this.kind,
      summary: summary ?? this.summary,
      facts: facts ?? this.facts,
      content: content ?? this.content,
      found: found ?? this.found,
      analysed: analysed ?? this.analysed,
      use: use ?? this.use,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (hlc.present) {
      map['hlc'] = Variable<String>(hlc.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (hash.present) {
      map['hash'] = Variable<String>(hash.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (summary.present) {
      map['summary'] = Variable<String>(summary.value);
    }
    if (facts.present) {
      map['facts'] = Variable<String>(facts.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (found.present) {
      map['found'] = Variable<String>(found.value);
    }
    if (analysed.present) {
      map['analysed'] = Variable<String>(analysed.value);
    }
    if (use.present) {
      map['use'] = Variable<bool>(use.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CareerDocumentsCompanion(')
          ..write('id: $id, ')
          ..write('hlc: $hlc, ')
          ..write('deleted: $deleted, ')
          ..write('hash: $hash, ')
          ..write('name: $name, ')
          ..write('kind: $kind, ')
          ..write('summary: $summary, ')
          ..write('facts: $facts, ')
          ..write('content: $content, ')
          ..write('found: $found, ')
          ..write('analysed: $analysed, ')
          ..write('use: $use, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CareerQuestionsTable extends CareerQuestions
    with TableInfo<$CareerQuestionsTable, ProfileQuestion> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CareerQuestionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hlcMeta = const VerificationMeta('hlc');
  @override
  late final GeneratedColumn<String> hlc = GeneratedColumn<String>(
    'hlc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _deletedMeta = const VerificationMeta(
    'deleted',
  );
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _topicMeta = const VerificationMeta('topic');
  @override
  late final GeneratedColumn<String> topic = GeneratedColumn<String>(
    'topic',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _questionMeta = const VerificationMeta(
    'question',
  );
  @override
  late final GeneratedColumn<String> question = GeneratedColumn<String>(
    'question',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _whyMeta = const VerificationMeta('why');
  @override
  late final GeneratedColumn<String> why = GeneratedColumn<String>(
    'why',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _choicesMeta = const VerificationMeta(
    'choices',
  );
  @override
  late final GeneratedColumn<String> choices = GeneratedColumn<String>(
    'choices',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('open'),
  );
  static const VerificationMeta _answerMeta = const VerificationMeta('answer');
  @override
  late final GeneratedColumn<String> answer = GeneratedColumn<String>(
    'answer',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _askedMeta = const VerificationMeta('asked');
  @override
  late final GeneratedColumn<String> asked = GeneratedColumn<String>(
    'asked',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _answeredMeta = const VerificationMeta(
    'answered',
  );
  @override
  late final GeneratedColumn<String> answered = GeneratedColumn<String>(
    'answered',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _appliedMeta = const VerificationMeta(
    'applied',
  );
  @override
  late final GeneratedColumn<bool> applied = GeneratedColumn<bool>(
    'applied',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("applied" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    hlc,
    deleted,
    topic,
    question,
    why,
    choices,
    status,
    answer,
    asked,
    answered,
    applied,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'career_questions';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProfileQuestion> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('hlc')) {
      context.handle(
        _hlcMeta,
        hlc.isAcceptableOrUnknown(data['hlc']!, _hlcMeta),
      );
    }
    if (data.containsKey('deleted')) {
      context.handle(
        _deletedMeta,
        deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta),
      );
    }
    if (data.containsKey('topic')) {
      context.handle(
        _topicMeta,
        topic.isAcceptableOrUnknown(data['topic']!, _topicMeta),
      );
    } else if (isInserting) {
      context.missing(_topicMeta);
    }
    if (data.containsKey('question')) {
      context.handle(
        _questionMeta,
        question.isAcceptableOrUnknown(data['question']!, _questionMeta),
      );
    } else if (isInserting) {
      context.missing(_questionMeta);
    }
    if (data.containsKey('why')) {
      context.handle(
        _whyMeta,
        why.isAcceptableOrUnknown(data['why']!, _whyMeta),
      );
    }
    if (data.containsKey('choices')) {
      context.handle(
        _choicesMeta,
        choices.isAcceptableOrUnknown(data['choices']!, _choicesMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('answer')) {
      context.handle(
        _answerMeta,
        answer.isAcceptableOrUnknown(data['answer']!, _answerMeta),
      );
    }
    if (data.containsKey('asked')) {
      context.handle(
        _askedMeta,
        asked.isAcceptableOrUnknown(data['asked']!, _askedMeta),
      );
    } else if (isInserting) {
      context.missing(_askedMeta);
    }
    if (data.containsKey('answered')) {
      context.handle(
        _answeredMeta,
        answered.isAcceptableOrUnknown(data['answered']!, _answeredMeta),
      );
    }
    if (data.containsKey('applied')) {
      context.handle(
        _appliedMeta,
        applied.isAcceptableOrUnknown(data['applied']!, _appliedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProfileQuestion map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProfileQuestion(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      hlc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hlc'],
      )!,
      deleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted'],
      )!,
      topic: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}topic'],
      )!,
      question: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}question'],
      )!,
      why: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}why'],
      )!,
      choices: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}choices'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      answer: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}answer'],
      )!,
      asked: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}asked'],
      )!,
      answered: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}answered'],
      ),
      applied: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}applied'],
      )!,
    );
  }

  @override
  $CareerQuestionsTable createAlias(String alias) {
    return $CareerQuestionsTable(attachedDatabase, alias);
  }
}

class ProfileQuestion extends DataClass implements Insertable<ProfileQuestion> {
  final String id;
  final String hlc;
  final bool deleted;

  /// What it is about, e.g. "Start date at Acme".
  final String topic;
  final String question;

  /// Why it is asked: the conflicting statements and where they are.
  final String why;

  /// Likely answers to pick from, JSON list of strings.
  final String choices;

  /// open | answered | dismissed
  final String status;
  final String answer;
  final String asked;
  final String? answered;

  /// True once the answer has been written into the profile.
  final bool applied;
  const ProfileQuestion({
    required this.id,
    required this.hlc,
    required this.deleted,
    required this.topic,
    required this.question,
    required this.why,
    required this.choices,
    required this.status,
    required this.answer,
    required this.asked,
    this.answered,
    required this.applied,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['hlc'] = Variable<String>(hlc);
    map['deleted'] = Variable<bool>(deleted);
    map['topic'] = Variable<String>(topic);
    map['question'] = Variable<String>(question);
    map['why'] = Variable<String>(why);
    map['choices'] = Variable<String>(choices);
    map['status'] = Variable<String>(status);
    map['answer'] = Variable<String>(answer);
    map['asked'] = Variable<String>(asked);
    if (!nullToAbsent || answered != null) {
      map['answered'] = Variable<String>(answered);
    }
    map['applied'] = Variable<bool>(applied);
    return map;
  }

  CareerQuestionsCompanion toCompanion(bool nullToAbsent) {
    return CareerQuestionsCompanion(
      id: Value(id),
      hlc: Value(hlc),
      deleted: Value(deleted),
      topic: Value(topic),
      question: Value(question),
      why: Value(why),
      choices: Value(choices),
      status: Value(status),
      answer: Value(answer),
      asked: Value(asked),
      answered: answered == null && nullToAbsent
          ? const Value.absent()
          : Value(answered),
      applied: Value(applied),
    );
  }

  factory ProfileQuestion.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProfileQuestion(
      id: serializer.fromJson<String>(json['id']),
      hlc: serializer.fromJson<String>(json['hlc']),
      deleted: serializer.fromJson<bool>(json['deleted']),
      topic: serializer.fromJson<String>(json['topic']),
      question: serializer.fromJson<String>(json['question']),
      why: serializer.fromJson<String>(json['why']),
      choices: serializer.fromJson<String>(json['choices']),
      status: serializer.fromJson<String>(json['status']),
      answer: serializer.fromJson<String>(json['answer']),
      asked: serializer.fromJson<String>(json['asked']),
      answered: serializer.fromJson<String?>(json['answered']),
      applied: serializer.fromJson<bool>(json['applied']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'hlc': serializer.toJson<String>(hlc),
      'deleted': serializer.toJson<bool>(deleted),
      'topic': serializer.toJson<String>(topic),
      'question': serializer.toJson<String>(question),
      'why': serializer.toJson<String>(why),
      'choices': serializer.toJson<String>(choices),
      'status': serializer.toJson<String>(status),
      'answer': serializer.toJson<String>(answer),
      'asked': serializer.toJson<String>(asked),
      'answered': serializer.toJson<String?>(answered),
      'applied': serializer.toJson<bool>(applied),
    };
  }

  ProfileQuestion copyWith({
    String? id,
    String? hlc,
    bool? deleted,
    String? topic,
    String? question,
    String? why,
    String? choices,
    String? status,
    String? answer,
    String? asked,
    Value<String?> answered = const Value.absent(),
    bool? applied,
  }) => ProfileQuestion(
    id: id ?? this.id,
    hlc: hlc ?? this.hlc,
    deleted: deleted ?? this.deleted,
    topic: topic ?? this.topic,
    question: question ?? this.question,
    why: why ?? this.why,
    choices: choices ?? this.choices,
    status: status ?? this.status,
    answer: answer ?? this.answer,
    asked: asked ?? this.asked,
    answered: answered.present ? answered.value : this.answered,
    applied: applied ?? this.applied,
  );
  ProfileQuestion copyWithCompanion(CareerQuestionsCompanion data) {
    return ProfileQuestion(
      id: data.id.present ? data.id.value : this.id,
      hlc: data.hlc.present ? data.hlc.value : this.hlc,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      topic: data.topic.present ? data.topic.value : this.topic,
      question: data.question.present ? data.question.value : this.question,
      why: data.why.present ? data.why.value : this.why,
      choices: data.choices.present ? data.choices.value : this.choices,
      status: data.status.present ? data.status.value : this.status,
      answer: data.answer.present ? data.answer.value : this.answer,
      asked: data.asked.present ? data.asked.value : this.asked,
      answered: data.answered.present ? data.answered.value : this.answered,
      applied: data.applied.present ? data.applied.value : this.applied,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProfileQuestion(')
          ..write('id: $id, ')
          ..write('hlc: $hlc, ')
          ..write('deleted: $deleted, ')
          ..write('topic: $topic, ')
          ..write('question: $question, ')
          ..write('why: $why, ')
          ..write('choices: $choices, ')
          ..write('status: $status, ')
          ..write('answer: $answer, ')
          ..write('asked: $asked, ')
          ..write('answered: $answered, ')
          ..write('applied: $applied')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    hlc,
    deleted,
    topic,
    question,
    why,
    choices,
    status,
    answer,
    asked,
    answered,
    applied,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProfileQuestion &&
          other.id == this.id &&
          other.hlc == this.hlc &&
          other.deleted == this.deleted &&
          other.topic == this.topic &&
          other.question == this.question &&
          other.why == this.why &&
          other.choices == this.choices &&
          other.status == this.status &&
          other.answer == this.answer &&
          other.asked == this.asked &&
          other.answered == this.answered &&
          other.applied == this.applied);
}

class CareerQuestionsCompanion extends UpdateCompanion<ProfileQuestion> {
  final Value<String> id;
  final Value<String> hlc;
  final Value<bool> deleted;
  final Value<String> topic;
  final Value<String> question;
  final Value<String> why;
  final Value<String> choices;
  final Value<String> status;
  final Value<String> answer;
  final Value<String> asked;
  final Value<String?> answered;
  final Value<bool> applied;
  final Value<int> rowid;
  const CareerQuestionsCompanion({
    this.id = const Value.absent(),
    this.hlc = const Value.absent(),
    this.deleted = const Value.absent(),
    this.topic = const Value.absent(),
    this.question = const Value.absent(),
    this.why = const Value.absent(),
    this.choices = const Value.absent(),
    this.status = const Value.absent(),
    this.answer = const Value.absent(),
    this.asked = const Value.absent(),
    this.answered = const Value.absent(),
    this.applied = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CareerQuestionsCompanion.insert({
    required String id,
    this.hlc = const Value.absent(),
    this.deleted = const Value.absent(),
    required String topic,
    required String question,
    this.why = const Value.absent(),
    this.choices = const Value.absent(),
    this.status = const Value.absent(),
    this.answer = const Value.absent(),
    required String asked,
    this.answered = const Value.absent(),
    this.applied = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       topic = Value(topic),
       question = Value(question),
       asked = Value(asked);
  static Insertable<ProfileQuestion> custom({
    Expression<String>? id,
    Expression<String>? hlc,
    Expression<bool>? deleted,
    Expression<String>? topic,
    Expression<String>? question,
    Expression<String>? why,
    Expression<String>? choices,
    Expression<String>? status,
    Expression<String>? answer,
    Expression<String>? asked,
    Expression<String>? answered,
    Expression<bool>? applied,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (hlc != null) 'hlc': hlc,
      if (deleted != null) 'deleted': deleted,
      if (topic != null) 'topic': topic,
      if (question != null) 'question': question,
      if (why != null) 'why': why,
      if (choices != null) 'choices': choices,
      if (status != null) 'status': status,
      if (answer != null) 'answer': answer,
      if (asked != null) 'asked': asked,
      if (answered != null) 'answered': answered,
      if (applied != null) 'applied': applied,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CareerQuestionsCompanion copyWith({
    Value<String>? id,
    Value<String>? hlc,
    Value<bool>? deleted,
    Value<String>? topic,
    Value<String>? question,
    Value<String>? why,
    Value<String>? choices,
    Value<String>? status,
    Value<String>? answer,
    Value<String>? asked,
    Value<String?>? answered,
    Value<bool>? applied,
    Value<int>? rowid,
  }) {
    return CareerQuestionsCompanion(
      id: id ?? this.id,
      hlc: hlc ?? this.hlc,
      deleted: deleted ?? this.deleted,
      topic: topic ?? this.topic,
      question: question ?? this.question,
      why: why ?? this.why,
      choices: choices ?? this.choices,
      status: status ?? this.status,
      answer: answer ?? this.answer,
      asked: asked ?? this.asked,
      answered: answered ?? this.answered,
      applied: applied ?? this.applied,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (hlc.present) {
      map['hlc'] = Variable<String>(hlc.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (topic.present) {
      map['topic'] = Variable<String>(topic.value);
    }
    if (question.present) {
      map['question'] = Variable<String>(question.value);
    }
    if (why.present) {
      map['why'] = Variable<String>(why.value);
    }
    if (choices.present) {
      map['choices'] = Variable<String>(choices.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (answer.present) {
      map['answer'] = Variable<String>(answer.value);
    }
    if (asked.present) {
      map['asked'] = Variable<String>(asked.value);
    }
    if (answered.present) {
      map['answered'] = Variable<String>(answered.value);
    }
    if (applied.present) {
      map['applied'] = Variable<bool>(applied.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CareerQuestionsCompanion(')
          ..write('id: $id, ')
          ..write('hlc: $hlc, ')
          ..write('deleted: $deleted, ')
          ..write('topic: $topic, ')
          ..write('question: $question, ')
          ..write('why: $why, ')
          ..write('choices: $choices, ')
          ..write('status: $status, ')
          ..write('answer: $answer, ')
          ..write('asked: $asked, ')
          ..write('answered: $answered, ')
          ..write('applied: $applied, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CareerJournalTable extends CareerJournal
    with TableInfo<$CareerJournalTable, CheckIn> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CareerJournalTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hlcMeta = const VerificationMeta('hlc');
  @override
  late final GeneratedColumn<String> hlc = GeneratedColumn<String>(
    'hlc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _deletedMeta = const VerificationMeta(
    'deleted',
  );
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<String> day = GeneratedColumn<String>(
    'day',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _promptMeta = const VerificationMeta('prompt');
  @override
  late final GeneratedColumn<String> prompt = GeneratedColumn<String>(
    'prompt',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entryMeta = const VerificationMeta('entry');
  @override
  late final GeneratedColumn<String> entry = GeneratedColumn<String>(
    'entry',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _digestMeta = const VerificationMeta('digest');
  @override
  late final GeneratedColumn<String> digest = GeneratedColumn<String>(
    'digest',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _atMeta = const VerificationMeta('at');
  @override
  late final GeneratedColumn<String> at = GeneratedColumn<String>(
    'at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    hlc,
    deleted,
    day,
    prompt,
    entry,
    digest,
    at,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'career_journal';
  @override
  VerificationContext validateIntegrity(
    Insertable<CheckIn> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('hlc')) {
      context.handle(
        _hlcMeta,
        hlc.isAcceptableOrUnknown(data['hlc']!, _hlcMeta),
      );
    }
    if (data.containsKey('deleted')) {
      context.handle(
        _deletedMeta,
        deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta),
      );
    }
    if (data.containsKey('day')) {
      context.handle(
        _dayMeta,
        day.isAcceptableOrUnknown(data['day']!, _dayMeta),
      );
    } else if (isInserting) {
      context.missing(_dayMeta);
    }
    if (data.containsKey('prompt')) {
      context.handle(
        _promptMeta,
        prompt.isAcceptableOrUnknown(data['prompt']!, _promptMeta),
      );
    } else if (isInserting) {
      context.missing(_promptMeta);
    }
    if (data.containsKey('entry')) {
      context.handle(
        _entryMeta,
        entry.isAcceptableOrUnknown(data['entry']!, _entryMeta),
      );
    }
    if (data.containsKey('digest')) {
      context.handle(
        _digestMeta,
        digest.isAcceptableOrUnknown(data['digest']!, _digestMeta),
      );
    }
    if (data.containsKey('at')) {
      context.handle(_atMeta, at.isAcceptableOrUnknown(data['at']!, _atMeta));
    } else if (isInserting) {
      context.missing(_atMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CheckIn map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CheckIn(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      hlc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hlc'],
      )!,
      deleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted'],
      )!,
      day: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}day'],
      )!,
      prompt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}prompt'],
      )!,
      entry: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entry'],
      )!,
      digest: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}digest'],
      )!,
      at: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}at'],
      )!,
    );
  }

  @override
  $CareerJournalTable createAlias(String alias) {
    return $CareerJournalTable(attachedDatabase, alias);
  }
}

class CheckIn extends DataClass implements Insertable<CheckIn> {
  final String id;
  final String hlc;
  final bool deleted;

  /// yyyy-MM-dd.
  final String day;
  final String prompt;
  final String entry;

  /// CheckInDigest as JSON, '' until read.
  final String digest;
  final String at;
  const CheckIn({
    required this.id,
    required this.hlc,
    required this.deleted,
    required this.day,
    required this.prompt,
    required this.entry,
    required this.digest,
    required this.at,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['hlc'] = Variable<String>(hlc);
    map['deleted'] = Variable<bool>(deleted);
    map['day'] = Variable<String>(day);
    map['prompt'] = Variable<String>(prompt);
    map['entry'] = Variable<String>(entry);
    map['digest'] = Variable<String>(digest);
    map['at'] = Variable<String>(at);
    return map;
  }

  CareerJournalCompanion toCompanion(bool nullToAbsent) {
    return CareerJournalCompanion(
      id: Value(id),
      hlc: Value(hlc),
      deleted: Value(deleted),
      day: Value(day),
      prompt: Value(prompt),
      entry: Value(entry),
      digest: Value(digest),
      at: Value(at),
    );
  }

  factory CheckIn.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CheckIn(
      id: serializer.fromJson<String>(json['id']),
      hlc: serializer.fromJson<String>(json['hlc']),
      deleted: serializer.fromJson<bool>(json['deleted']),
      day: serializer.fromJson<String>(json['day']),
      prompt: serializer.fromJson<String>(json['prompt']),
      entry: serializer.fromJson<String>(json['entry']),
      digest: serializer.fromJson<String>(json['digest']),
      at: serializer.fromJson<String>(json['at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'hlc': serializer.toJson<String>(hlc),
      'deleted': serializer.toJson<bool>(deleted),
      'day': serializer.toJson<String>(day),
      'prompt': serializer.toJson<String>(prompt),
      'entry': serializer.toJson<String>(entry),
      'digest': serializer.toJson<String>(digest),
      'at': serializer.toJson<String>(at),
    };
  }

  CheckIn copyWith({
    String? id,
    String? hlc,
    bool? deleted,
    String? day,
    String? prompt,
    String? entry,
    String? digest,
    String? at,
  }) => CheckIn(
    id: id ?? this.id,
    hlc: hlc ?? this.hlc,
    deleted: deleted ?? this.deleted,
    day: day ?? this.day,
    prompt: prompt ?? this.prompt,
    entry: entry ?? this.entry,
    digest: digest ?? this.digest,
    at: at ?? this.at,
  );
  CheckIn copyWithCompanion(CareerJournalCompanion data) {
    return CheckIn(
      id: data.id.present ? data.id.value : this.id,
      hlc: data.hlc.present ? data.hlc.value : this.hlc,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      day: data.day.present ? data.day.value : this.day,
      prompt: data.prompt.present ? data.prompt.value : this.prompt,
      entry: data.entry.present ? data.entry.value : this.entry,
      digest: data.digest.present ? data.digest.value : this.digest,
      at: data.at.present ? data.at.value : this.at,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CheckIn(')
          ..write('id: $id, ')
          ..write('hlc: $hlc, ')
          ..write('deleted: $deleted, ')
          ..write('day: $day, ')
          ..write('prompt: $prompt, ')
          ..write('entry: $entry, ')
          ..write('digest: $digest, ')
          ..write('at: $at')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, hlc, deleted, day, prompt, entry, digest, at);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CheckIn &&
          other.id == this.id &&
          other.hlc == this.hlc &&
          other.deleted == this.deleted &&
          other.day == this.day &&
          other.prompt == this.prompt &&
          other.entry == this.entry &&
          other.digest == this.digest &&
          other.at == this.at);
}

class CareerJournalCompanion extends UpdateCompanion<CheckIn> {
  final Value<String> id;
  final Value<String> hlc;
  final Value<bool> deleted;
  final Value<String> day;
  final Value<String> prompt;
  final Value<String> entry;
  final Value<String> digest;
  final Value<String> at;
  final Value<int> rowid;
  const CareerJournalCompanion({
    this.id = const Value.absent(),
    this.hlc = const Value.absent(),
    this.deleted = const Value.absent(),
    this.day = const Value.absent(),
    this.prompt = const Value.absent(),
    this.entry = const Value.absent(),
    this.digest = const Value.absent(),
    this.at = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CareerJournalCompanion.insert({
    required String id,
    this.hlc = const Value.absent(),
    this.deleted = const Value.absent(),
    required String day,
    required String prompt,
    this.entry = const Value.absent(),
    this.digest = const Value.absent(),
    required String at,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       day = Value(day),
       prompt = Value(prompt),
       at = Value(at);
  static Insertable<CheckIn> custom({
    Expression<String>? id,
    Expression<String>? hlc,
    Expression<bool>? deleted,
    Expression<String>? day,
    Expression<String>? prompt,
    Expression<String>? entry,
    Expression<String>? digest,
    Expression<String>? at,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (hlc != null) 'hlc': hlc,
      if (deleted != null) 'deleted': deleted,
      if (day != null) 'day': day,
      if (prompt != null) 'prompt': prompt,
      if (entry != null) 'entry': entry,
      if (digest != null) 'digest': digest,
      if (at != null) 'at': at,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CareerJournalCompanion copyWith({
    Value<String>? id,
    Value<String>? hlc,
    Value<bool>? deleted,
    Value<String>? day,
    Value<String>? prompt,
    Value<String>? entry,
    Value<String>? digest,
    Value<String>? at,
    Value<int>? rowid,
  }) {
    return CareerJournalCompanion(
      id: id ?? this.id,
      hlc: hlc ?? this.hlc,
      deleted: deleted ?? this.deleted,
      day: day ?? this.day,
      prompt: prompt ?? this.prompt,
      entry: entry ?? this.entry,
      digest: digest ?? this.digest,
      at: at ?? this.at,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (hlc.present) {
      map['hlc'] = Variable<String>(hlc.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (day.present) {
      map['day'] = Variable<String>(day.value);
    }
    if (prompt.present) {
      map['prompt'] = Variable<String>(prompt.value);
    }
    if (entry.present) {
      map['entry'] = Variable<String>(entry.value);
    }
    if (digest.present) {
      map['digest'] = Variable<String>(digest.value);
    }
    if (at.present) {
      map['at'] = Variable<String>(at.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CareerJournalCompanion(')
          ..write('id: $id, ')
          ..write('hlc: $hlc, ')
          ..write('deleted: $deleted, ')
          ..write('day: $day, ')
          ..write('prompt: $prompt, ')
          ..write('entry: $entry, ')
          ..write('digest: $digest, ')
          ..write('at: $at, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CareerStoriesTable extends CareerStories
    with TableInfo<$CareerStoriesTable, Story> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CareerStoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hlcMeta = const VerificationMeta('hlc');
  @override
  late final GeneratedColumn<String> hlc = GeneratedColumn<String>(
    'hlc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _deletedMeta = const VerificationMeta(
    'deleted',
  );
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _situationMeta = const VerificationMeta(
    'situation',
  );
  @override
  late final GeneratedColumn<String> situation = GeneratedColumn<String>(
    'situation',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _taskMeta = const VerificationMeta('task');
  @override
  late final GeneratedColumn<String> task = GeneratedColumn<String>(
    'task',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _actionMeta = const VerificationMeta('action');
  @override
  late final GeneratedColumn<String> action = GeneratedColumn<String>(
    'action',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _resultMeta = const VerificationMeta('result');
  @override
  late final GeneratedColumn<String> result = GeneratedColumn<String>(
    'result',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _competenciesMeta = const VerificationMeta(
    'competencies',
  );
  @override
  late final GeneratedColumn<String> competencies = GeneratedColumn<String>(
    'competencies',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('manual'),
  );
  static const VerificationMeta _sourceIdMeta = const VerificationMeta(
    'sourceId',
  );
  @override
  late final GeneratedColumn<String> sourceId = GeneratedColumn<String>(
    'source_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _criteriaMeta = const VerificationMeta(
    'criteria',
  );
  @override
  late final GeneratedColumn<String> criteria = GeneratedColumn<String>(
    'criteria',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _confirmedMeta = const VerificationMeta(
    'confirmed',
  );
  @override
  late final GeneratedColumn<bool> confirmed = GeneratedColumn<bool>(
    'confirmed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("confirmed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _addedMeta = const VerificationMeta('added');
  @override
  late final GeneratedColumn<String> added = GeneratedColumn<String>(
    'added',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    hlc,
    deleted,
    title,
    situation,
    task,
    action,
    result,
    competencies,
    source,
    sourceId,
    criteria,
    confirmed,
    added,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'career_stories';
  @override
  VerificationContext validateIntegrity(
    Insertable<Story> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('hlc')) {
      context.handle(
        _hlcMeta,
        hlc.isAcceptableOrUnknown(data['hlc']!, _hlcMeta),
      );
    }
    if (data.containsKey('deleted')) {
      context.handle(
        _deletedMeta,
        deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('situation')) {
      context.handle(
        _situationMeta,
        situation.isAcceptableOrUnknown(data['situation']!, _situationMeta),
      );
    }
    if (data.containsKey('task')) {
      context.handle(
        _taskMeta,
        task.isAcceptableOrUnknown(data['task']!, _taskMeta),
      );
    }
    if (data.containsKey('action')) {
      context.handle(
        _actionMeta,
        action.isAcceptableOrUnknown(data['action']!, _actionMeta),
      );
    }
    if (data.containsKey('result')) {
      context.handle(
        _resultMeta,
        result.isAcceptableOrUnknown(data['result']!, _resultMeta),
      );
    }
    if (data.containsKey('competencies')) {
      context.handle(
        _competenciesMeta,
        competencies.isAcceptableOrUnknown(
          data['competencies']!,
          _competenciesMeta,
        ),
      );
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    if (data.containsKey('source_id')) {
      context.handle(
        _sourceIdMeta,
        sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta),
      );
    }
    if (data.containsKey('criteria')) {
      context.handle(
        _criteriaMeta,
        criteria.isAcceptableOrUnknown(data['criteria']!, _criteriaMeta),
      );
    }
    if (data.containsKey('confirmed')) {
      context.handle(
        _confirmedMeta,
        confirmed.isAcceptableOrUnknown(data['confirmed']!, _confirmedMeta),
      );
    }
    if (data.containsKey('added')) {
      context.handle(
        _addedMeta,
        added.isAcceptableOrUnknown(data['added']!, _addedMeta),
      );
    } else if (isInserting) {
      context.missing(_addedMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Story map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Story(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      hlc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hlc'],
      )!,
      deleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      situation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}situation'],
      )!,
      task: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}task'],
      )!,
      action: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}action'],
      )!,
      result: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}result'],
      )!,
      competencies: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}competencies'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_id'],
      ),
      criteria: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}criteria'],
      )!,
      confirmed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}confirmed'],
      )!,
      added: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}added'],
      )!,
    );
  }

  @override
  $CareerStoriesTable createAlias(String alias) {
    return $CareerStoriesTable(attachedDatabase, alias);
  }
}

class Story extends DataClass implements Insertable<Story> {
  final String id;
  final String hlc;
  final bool deleted;
  final String title;
  final String situation;
  final String task;
  final String action;
  final String result;

  /// Competency ids (domain/companion.dart), JSON list.
  final String competencies;

  /// checkin | document | practice | manual
  final String source;
  final String? sourceId;

  /// The role criteria a practice answer evidenced, JSON list of text.
  final String criteria;

  /// False until the candidate has checked it is true as written.
  final bool confirmed;
  final String added;
  const Story({
    required this.id,
    required this.hlc,
    required this.deleted,
    required this.title,
    required this.situation,
    required this.task,
    required this.action,
    required this.result,
    required this.competencies,
    required this.source,
    this.sourceId,
    required this.criteria,
    required this.confirmed,
    required this.added,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['hlc'] = Variable<String>(hlc);
    map['deleted'] = Variable<bool>(deleted);
    map['title'] = Variable<String>(title);
    map['situation'] = Variable<String>(situation);
    map['task'] = Variable<String>(task);
    map['action'] = Variable<String>(action);
    map['result'] = Variable<String>(result);
    map['competencies'] = Variable<String>(competencies);
    map['source'] = Variable<String>(source);
    if (!nullToAbsent || sourceId != null) {
      map['source_id'] = Variable<String>(sourceId);
    }
    map['criteria'] = Variable<String>(criteria);
    map['confirmed'] = Variable<bool>(confirmed);
    map['added'] = Variable<String>(added);
    return map;
  }

  CareerStoriesCompanion toCompanion(bool nullToAbsent) {
    return CareerStoriesCompanion(
      id: Value(id),
      hlc: Value(hlc),
      deleted: Value(deleted),
      title: Value(title),
      situation: Value(situation),
      task: Value(task),
      action: Value(action),
      result: Value(result),
      competencies: Value(competencies),
      source: Value(source),
      sourceId: sourceId == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceId),
      criteria: Value(criteria),
      confirmed: Value(confirmed),
      added: Value(added),
    );
  }

  factory Story.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Story(
      id: serializer.fromJson<String>(json['id']),
      hlc: serializer.fromJson<String>(json['hlc']),
      deleted: serializer.fromJson<bool>(json['deleted']),
      title: serializer.fromJson<String>(json['title']),
      situation: serializer.fromJson<String>(json['situation']),
      task: serializer.fromJson<String>(json['task']),
      action: serializer.fromJson<String>(json['action']),
      result: serializer.fromJson<String>(json['result']),
      competencies: serializer.fromJson<String>(json['competencies']),
      source: serializer.fromJson<String>(json['source']),
      sourceId: serializer.fromJson<String?>(json['sourceId']),
      criteria: serializer.fromJson<String>(json['criteria']),
      confirmed: serializer.fromJson<bool>(json['confirmed']),
      added: serializer.fromJson<String>(json['added']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'hlc': serializer.toJson<String>(hlc),
      'deleted': serializer.toJson<bool>(deleted),
      'title': serializer.toJson<String>(title),
      'situation': serializer.toJson<String>(situation),
      'task': serializer.toJson<String>(task),
      'action': serializer.toJson<String>(action),
      'result': serializer.toJson<String>(result),
      'competencies': serializer.toJson<String>(competencies),
      'source': serializer.toJson<String>(source),
      'sourceId': serializer.toJson<String?>(sourceId),
      'criteria': serializer.toJson<String>(criteria),
      'confirmed': serializer.toJson<bool>(confirmed),
      'added': serializer.toJson<String>(added),
    };
  }

  Story copyWith({
    String? id,
    String? hlc,
    bool? deleted,
    String? title,
    String? situation,
    String? task,
    String? action,
    String? result,
    String? competencies,
    String? source,
    Value<String?> sourceId = const Value.absent(),
    String? criteria,
    bool? confirmed,
    String? added,
  }) => Story(
    id: id ?? this.id,
    hlc: hlc ?? this.hlc,
    deleted: deleted ?? this.deleted,
    title: title ?? this.title,
    situation: situation ?? this.situation,
    task: task ?? this.task,
    action: action ?? this.action,
    result: result ?? this.result,
    competencies: competencies ?? this.competencies,
    source: source ?? this.source,
    sourceId: sourceId.present ? sourceId.value : this.sourceId,
    criteria: criteria ?? this.criteria,
    confirmed: confirmed ?? this.confirmed,
    added: added ?? this.added,
  );
  Story copyWithCompanion(CareerStoriesCompanion data) {
    return Story(
      id: data.id.present ? data.id.value : this.id,
      hlc: data.hlc.present ? data.hlc.value : this.hlc,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      title: data.title.present ? data.title.value : this.title,
      situation: data.situation.present ? data.situation.value : this.situation,
      task: data.task.present ? data.task.value : this.task,
      action: data.action.present ? data.action.value : this.action,
      result: data.result.present ? data.result.value : this.result,
      competencies: data.competencies.present
          ? data.competencies.value
          : this.competencies,
      source: data.source.present ? data.source.value : this.source,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      criteria: data.criteria.present ? data.criteria.value : this.criteria,
      confirmed: data.confirmed.present ? data.confirmed.value : this.confirmed,
      added: data.added.present ? data.added.value : this.added,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Story(')
          ..write('id: $id, ')
          ..write('hlc: $hlc, ')
          ..write('deleted: $deleted, ')
          ..write('title: $title, ')
          ..write('situation: $situation, ')
          ..write('task: $task, ')
          ..write('action: $action, ')
          ..write('result: $result, ')
          ..write('competencies: $competencies, ')
          ..write('source: $source, ')
          ..write('sourceId: $sourceId, ')
          ..write('criteria: $criteria, ')
          ..write('confirmed: $confirmed, ')
          ..write('added: $added')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    hlc,
    deleted,
    title,
    situation,
    task,
    action,
    result,
    competencies,
    source,
    sourceId,
    criteria,
    confirmed,
    added,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Story &&
          other.id == this.id &&
          other.hlc == this.hlc &&
          other.deleted == this.deleted &&
          other.title == this.title &&
          other.situation == this.situation &&
          other.task == this.task &&
          other.action == this.action &&
          other.result == this.result &&
          other.competencies == this.competencies &&
          other.source == this.source &&
          other.sourceId == this.sourceId &&
          other.criteria == this.criteria &&
          other.confirmed == this.confirmed &&
          other.added == this.added);
}

class CareerStoriesCompanion extends UpdateCompanion<Story> {
  final Value<String> id;
  final Value<String> hlc;
  final Value<bool> deleted;
  final Value<String> title;
  final Value<String> situation;
  final Value<String> task;
  final Value<String> action;
  final Value<String> result;
  final Value<String> competencies;
  final Value<String> source;
  final Value<String?> sourceId;
  final Value<String> criteria;
  final Value<bool> confirmed;
  final Value<String> added;
  final Value<int> rowid;
  const CareerStoriesCompanion({
    this.id = const Value.absent(),
    this.hlc = const Value.absent(),
    this.deleted = const Value.absent(),
    this.title = const Value.absent(),
    this.situation = const Value.absent(),
    this.task = const Value.absent(),
    this.action = const Value.absent(),
    this.result = const Value.absent(),
    this.competencies = const Value.absent(),
    this.source = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.criteria = const Value.absent(),
    this.confirmed = const Value.absent(),
    this.added = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CareerStoriesCompanion.insert({
    required String id,
    this.hlc = const Value.absent(),
    this.deleted = const Value.absent(),
    required String title,
    this.situation = const Value.absent(),
    this.task = const Value.absent(),
    this.action = const Value.absent(),
    this.result = const Value.absent(),
    this.competencies = const Value.absent(),
    this.source = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.criteria = const Value.absent(),
    this.confirmed = const Value.absent(),
    required String added,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       added = Value(added);
  static Insertable<Story> custom({
    Expression<String>? id,
    Expression<String>? hlc,
    Expression<bool>? deleted,
    Expression<String>? title,
    Expression<String>? situation,
    Expression<String>? task,
    Expression<String>? action,
    Expression<String>? result,
    Expression<String>? competencies,
    Expression<String>? source,
    Expression<String>? sourceId,
    Expression<String>? criteria,
    Expression<bool>? confirmed,
    Expression<String>? added,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (hlc != null) 'hlc': hlc,
      if (deleted != null) 'deleted': deleted,
      if (title != null) 'title': title,
      if (situation != null) 'situation': situation,
      if (task != null) 'task': task,
      if (action != null) 'action': action,
      if (result != null) 'result': result,
      if (competencies != null) 'competencies': competencies,
      if (source != null) 'source': source,
      if (sourceId != null) 'source_id': sourceId,
      if (criteria != null) 'criteria': criteria,
      if (confirmed != null) 'confirmed': confirmed,
      if (added != null) 'added': added,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CareerStoriesCompanion copyWith({
    Value<String>? id,
    Value<String>? hlc,
    Value<bool>? deleted,
    Value<String>? title,
    Value<String>? situation,
    Value<String>? task,
    Value<String>? action,
    Value<String>? result,
    Value<String>? competencies,
    Value<String>? source,
    Value<String?>? sourceId,
    Value<String>? criteria,
    Value<bool>? confirmed,
    Value<String>? added,
    Value<int>? rowid,
  }) {
    return CareerStoriesCompanion(
      id: id ?? this.id,
      hlc: hlc ?? this.hlc,
      deleted: deleted ?? this.deleted,
      title: title ?? this.title,
      situation: situation ?? this.situation,
      task: task ?? this.task,
      action: action ?? this.action,
      result: result ?? this.result,
      competencies: competencies ?? this.competencies,
      source: source ?? this.source,
      sourceId: sourceId ?? this.sourceId,
      criteria: criteria ?? this.criteria,
      confirmed: confirmed ?? this.confirmed,
      added: added ?? this.added,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (hlc.present) {
      map['hlc'] = Variable<String>(hlc.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (situation.present) {
      map['situation'] = Variable<String>(situation.value);
    }
    if (task.present) {
      map['task'] = Variable<String>(task.value);
    }
    if (action.present) {
      map['action'] = Variable<String>(action.value);
    }
    if (result.present) {
      map['result'] = Variable<String>(result.value);
    }
    if (competencies.present) {
      map['competencies'] = Variable<String>(competencies.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (sourceId.present) {
      map['source_id'] = Variable<String>(sourceId.value);
    }
    if (criteria.present) {
      map['criteria'] = Variable<String>(criteria.value);
    }
    if (confirmed.present) {
      map['confirmed'] = Variable<bool>(confirmed.value);
    }
    if (added.present) {
      map['added'] = Variable<String>(added.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CareerStoriesCompanion(')
          ..write('id: $id, ')
          ..write('hlc: $hlc, ')
          ..write('deleted: $deleted, ')
          ..write('title: $title, ')
          ..write('situation: $situation, ')
          ..write('task: $task, ')
          ..write('action: $action, ')
          ..write('result: $result, ')
          ..write('competencies: $competencies, ')
          ..write('source: $source, ')
          ..write('sourceId: $sourceId, ')
          ..write('criteria: $criteria, ')
          ..write('confirmed: $confirmed, ')
          ..write('added: $added, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ContactHandlesTable extends ContactHandles
    with TableInfo<$ContactHandlesTable, ContactHandle> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ContactHandlesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hlcMeta = const VerificationMeta('hlc');
  @override
  late final GeneratedColumn<String> hlc = GeneratedColumn<String>(
    'hlc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _deletedMeta = const VerificationMeta(
    'deleted',
  );
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _contactIdMeta = const VerificationMeta(
    'contactId',
  );
  @override
  late final GeneratedColumn<String> contactId = GeneratedColumn<String>(
    'contact_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _channelMeta = const VerificationMeta(
    'channel',
  );
  @override
  late final GeneratedColumn<String> channel = GeneratedColumn<String>(
    'channel',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _handleMeta = const VerificationMeta('handle');
  @override
  late final GeneratedColumn<String> handle = GeneratedColumn<String>(
    'handle',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accountMeta = const VerificationMeta(
    'account',
  );
  @override
  late final GeneratedColumn<String> account = GeneratedColumn<String>(
    'account',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _primaryMeta = const VerificationMeta(
    'primary',
  );
  @override
  late final GeneratedColumn<bool> primary = GeneratedColumn<bool>(
    'is_primary',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_primary" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    hlc,
    deleted,
    contactId,
    channel,
    handle,
    account,
    primary,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'career_handles';
  @override
  VerificationContext validateIntegrity(
    Insertable<ContactHandle> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('hlc')) {
      context.handle(
        _hlcMeta,
        hlc.isAcceptableOrUnknown(data['hlc']!, _hlcMeta),
      );
    }
    if (data.containsKey('deleted')) {
      context.handle(
        _deletedMeta,
        deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta),
      );
    }
    if (data.containsKey('contact_id')) {
      context.handle(
        _contactIdMeta,
        contactId.isAcceptableOrUnknown(data['contact_id']!, _contactIdMeta),
      );
    } else if (isInserting) {
      context.missing(_contactIdMeta);
    }
    if (data.containsKey('channel')) {
      context.handle(
        _channelMeta,
        channel.isAcceptableOrUnknown(data['channel']!, _channelMeta),
      );
    } else if (isInserting) {
      context.missing(_channelMeta);
    }
    if (data.containsKey('handle')) {
      context.handle(
        _handleMeta,
        handle.isAcceptableOrUnknown(data['handle']!, _handleMeta),
      );
    } else if (isInserting) {
      context.missing(_handleMeta);
    }
    if (data.containsKey('account')) {
      context.handle(
        _accountMeta,
        account.isAcceptableOrUnknown(data['account']!, _accountMeta),
      );
    }
    if (data.containsKey('is_primary')) {
      context.handle(
        _primaryMeta,
        primary.isAcceptableOrUnknown(data['is_primary']!, _primaryMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ContactHandle map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ContactHandle(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      hlc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hlc'],
      )!,
      deleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted'],
      )!,
      contactId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}contact_id'],
      )!,
      channel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}channel'],
      )!,
      handle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}handle'],
      )!,
      account: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account'],
      )!,
      primary: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_primary'],
      )!,
    );
  }

  @override
  $ContactHandlesTable createAlias(String alias) {
    return $ContactHandlesTable(attachedDatabase, alias);
  }
}

class ContactHandle extends DataClass implements Insertable<ContactHandle> {
  final String id;
  final String hlc;
  final bool deleted;
  final String contactId;

  /// email | linkedin | bluesky | phone | in_person | other
  final String channel;

  /// The address, profile URL, Bluesky handle or number.
  final String handle;

  /// Which of the user's own accounts talks to it ('' for any).
  final String account;

  /// The one to use first on this channel. ("primary" is an SQL keyword.)
  final bool primary;
  const ContactHandle({
    required this.id,
    required this.hlc,
    required this.deleted,
    required this.contactId,
    required this.channel,
    required this.handle,
    required this.account,
    required this.primary,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['hlc'] = Variable<String>(hlc);
    map['deleted'] = Variable<bool>(deleted);
    map['contact_id'] = Variable<String>(contactId);
    map['channel'] = Variable<String>(channel);
    map['handle'] = Variable<String>(handle);
    map['account'] = Variable<String>(account);
    map['is_primary'] = Variable<bool>(primary);
    return map;
  }

  ContactHandlesCompanion toCompanion(bool nullToAbsent) {
    return ContactHandlesCompanion(
      id: Value(id),
      hlc: Value(hlc),
      deleted: Value(deleted),
      contactId: Value(contactId),
      channel: Value(channel),
      handle: Value(handle),
      account: Value(account),
      primary: Value(primary),
    );
  }

  factory ContactHandle.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ContactHandle(
      id: serializer.fromJson<String>(json['id']),
      hlc: serializer.fromJson<String>(json['hlc']),
      deleted: serializer.fromJson<bool>(json['deleted']),
      contactId: serializer.fromJson<String>(json['contactId']),
      channel: serializer.fromJson<String>(json['channel']),
      handle: serializer.fromJson<String>(json['handle']),
      account: serializer.fromJson<String>(json['account']),
      primary: serializer.fromJson<bool>(json['primary']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'hlc': serializer.toJson<String>(hlc),
      'deleted': serializer.toJson<bool>(deleted),
      'contactId': serializer.toJson<String>(contactId),
      'channel': serializer.toJson<String>(channel),
      'handle': serializer.toJson<String>(handle),
      'account': serializer.toJson<String>(account),
      'primary': serializer.toJson<bool>(primary),
    };
  }

  ContactHandle copyWith({
    String? id,
    String? hlc,
    bool? deleted,
    String? contactId,
    String? channel,
    String? handle,
    String? account,
    bool? primary,
  }) => ContactHandle(
    id: id ?? this.id,
    hlc: hlc ?? this.hlc,
    deleted: deleted ?? this.deleted,
    contactId: contactId ?? this.contactId,
    channel: channel ?? this.channel,
    handle: handle ?? this.handle,
    account: account ?? this.account,
    primary: primary ?? this.primary,
  );
  ContactHandle copyWithCompanion(ContactHandlesCompanion data) {
    return ContactHandle(
      id: data.id.present ? data.id.value : this.id,
      hlc: data.hlc.present ? data.hlc.value : this.hlc,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      contactId: data.contactId.present ? data.contactId.value : this.contactId,
      channel: data.channel.present ? data.channel.value : this.channel,
      handle: data.handle.present ? data.handle.value : this.handle,
      account: data.account.present ? data.account.value : this.account,
      primary: data.primary.present ? data.primary.value : this.primary,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ContactHandle(')
          ..write('id: $id, ')
          ..write('hlc: $hlc, ')
          ..write('deleted: $deleted, ')
          ..write('contactId: $contactId, ')
          ..write('channel: $channel, ')
          ..write('handle: $handle, ')
          ..write('account: $account, ')
          ..write('primary: $primary')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    hlc,
    deleted,
    contactId,
    channel,
    handle,
    account,
    primary,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ContactHandle &&
          other.id == this.id &&
          other.hlc == this.hlc &&
          other.deleted == this.deleted &&
          other.contactId == this.contactId &&
          other.channel == this.channel &&
          other.handle == this.handle &&
          other.account == this.account &&
          other.primary == this.primary);
}

class ContactHandlesCompanion extends UpdateCompanion<ContactHandle> {
  final Value<String> id;
  final Value<String> hlc;
  final Value<bool> deleted;
  final Value<String> contactId;
  final Value<String> channel;
  final Value<String> handle;
  final Value<String> account;
  final Value<bool> primary;
  final Value<int> rowid;
  const ContactHandlesCompanion({
    this.id = const Value.absent(),
    this.hlc = const Value.absent(),
    this.deleted = const Value.absent(),
    this.contactId = const Value.absent(),
    this.channel = const Value.absent(),
    this.handle = const Value.absent(),
    this.account = const Value.absent(),
    this.primary = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ContactHandlesCompanion.insert({
    required String id,
    this.hlc = const Value.absent(),
    this.deleted = const Value.absent(),
    required String contactId,
    required String channel,
    required String handle,
    this.account = const Value.absent(),
    this.primary = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       contactId = Value(contactId),
       channel = Value(channel),
       handle = Value(handle);
  static Insertable<ContactHandle> custom({
    Expression<String>? id,
    Expression<String>? hlc,
    Expression<bool>? deleted,
    Expression<String>? contactId,
    Expression<String>? channel,
    Expression<String>? handle,
    Expression<String>? account,
    Expression<bool>? primary,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (hlc != null) 'hlc': hlc,
      if (deleted != null) 'deleted': deleted,
      if (contactId != null) 'contact_id': contactId,
      if (channel != null) 'channel': channel,
      if (handle != null) 'handle': handle,
      if (account != null) 'account': account,
      if (primary != null) 'is_primary': primary,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ContactHandlesCompanion copyWith({
    Value<String>? id,
    Value<String>? hlc,
    Value<bool>? deleted,
    Value<String>? contactId,
    Value<String>? channel,
    Value<String>? handle,
    Value<String>? account,
    Value<bool>? primary,
    Value<int>? rowid,
  }) {
    return ContactHandlesCompanion(
      id: id ?? this.id,
      hlc: hlc ?? this.hlc,
      deleted: deleted ?? this.deleted,
      contactId: contactId ?? this.contactId,
      channel: channel ?? this.channel,
      handle: handle ?? this.handle,
      account: account ?? this.account,
      primary: primary ?? this.primary,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (hlc.present) {
      map['hlc'] = Variable<String>(hlc.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (contactId.present) {
      map['contact_id'] = Variable<String>(contactId.value);
    }
    if (channel.present) {
      map['channel'] = Variable<String>(channel.value);
    }
    if (handle.present) {
      map['handle'] = Variable<String>(handle.value);
    }
    if (account.present) {
      map['account'] = Variable<String>(account.value);
    }
    if (primary.present) {
      map['is_primary'] = Variable<bool>(primary.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ContactHandlesCompanion(')
          ..write('id: $id, ')
          ..write('hlc: $hlc, ')
          ..write('deleted: $deleted, ')
          ..write('contactId: $contactId, ')
          ..write('channel: $channel, ')
          ..write('handle: $handle, ')
          ..write('account: $account, ')
          ..write('primary: $primary, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ConversationsTable extends Conversations
    with TableInfo<$ConversationsTable, Conversation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ConversationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hlcMeta = const VerificationMeta('hlc');
  @override
  late final GeneratedColumn<String> hlc = GeneratedColumn<String>(
    'hlc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _deletedMeta = const VerificationMeta(
    'deleted',
  );
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _contactIdMeta = const VerificationMeta(
    'contactId',
  );
  @override
  late final GeneratedColumn<String> contactId = GeneratedColumn<String>(
    'contact_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _channelMeta = const VerificationMeta(
    'channel',
  );
  @override
  late final GeneratedColumn<String> channel = GeneratedColumn<String>(
    'channel',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accountMeta = const VerificationMeta(
    'account',
  );
  @override
  late final GeneratedColumn<String> account = GeneratedColumn<String>(
    'account',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _modeMeta = const VerificationMeta('mode');
  @override
  late final GeneratedColumn<String> mode = GeneratedColumn<String>(
    'mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('manual'),
  );
  static const VerificationMeta _externalIdMeta = const VerificationMeta(
    'externalId',
  );
  @override
  late final GeneratedColumn<String> externalId = GeneratedColumn<String>(
    'external_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _peerMeta = const VerificationMeta('peer');
  @override
  late final GeneratedColumn<String> peer = GeneratedColumn<String>(
    'peer',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _subjectMeta = const VerificationMeta(
    'subject',
  );
  @override
  late final GeneratedColumn<String> subject = GeneratedColumn<String>(
    'subject',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('draft'),
  );
  static const VerificationMeta _followUpMeta = const VerificationMeta(
    'followUp',
  );
  @override
  late final GeneratedColumn<String> followUp = GeneratedColumn<String>(
    'follow_up',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _jobIdMeta = const VerificationMeta('jobId');
  @override
  late final GeneratedColumn<String> jobId = GeneratedColumn<String>(
    'job_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastAtMeta = const VerificationMeta('lastAt');
  @override
  late final GeneratedColumn<String> lastAt = GeneratedColumn<String>(
    'last_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _unreadMeta = const VerificationMeta('unread');
  @override
  late final GeneratedColumn<int> unread = GeneratedColumn<int>(
    'unread',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    hlc,
    deleted,
    contactId,
    channel,
    account,
    mode,
    externalId,
    peer,
    subject,
    status,
    followUp,
    jobId,
    lastAt,
    unread,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'career_conversations';
  @override
  VerificationContext validateIntegrity(
    Insertable<Conversation> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('hlc')) {
      context.handle(
        _hlcMeta,
        hlc.isAcceptableOrUnknown(data['hlc']!, _hlcMeta),
      );
    }
    if (data.containsKey('deleted')) {
      context.handle(
        _deletedMeta,
        deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta),
      );
    }
    if (data.containsKey('contact_id')) {
      context.handle(
        _contactIdMeta,
        contactId.isAcceptableOrUnknown(data['contact_id']!, _contactIdMeta),
      );
    }
    if (data.containsKey('channel')) {
      context.handle(
        _channelMeta,
        channel.isAcceptableOrUnknown(data['channel']!, _channelMeta),
      );
    } else if (isInserting) {
      context.missing(_channelMeta);
    }
    if (data.containsKey('account')) {
      context.handle(
        _accountMeta,
        account.isAcceptableOrUnknown(data['account']!, _accountMeta),
      );
    }
    if (data.containsKey('mode')) {
      context.handle(
        _modeMeta,
        mode.isAcceptableOrUnknown(data['mode']!, _modeMeta),
      );
    }
    if (data.containsKey('external_id')) {
      context.handle(
        _externalIdMeta,
        externalId.isAcceptableOrUnknown(data['external_id']!, _externalIdMeta),
      );
    }
    if (data.containsKey('peer')) {
      context.handle(
        _peerMeta,
        peer.isAcceptableOrUnknown(data['peer']!, _peerMeta),
      );
    }
    if (data.containsKey('subject')) {
      context.handle(
        _subjectMeta,
        subject.isAcceptableOrUnknown(data['subject']!, _subjectMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('follow_up')) {
      context.handle(
        _followUpMeta,
        followUp.isAcceptableOrUnknown(data['follow_up']!, _followUpMeta),
      );
    }
    if (data.containsKey('job_id')) {
      context.handle(
        _jobIdMeta,
        jobId.isAcceptableOrUnknown(data['job_id']!, _jobIdMeta),
      );
    }
    if (data.containsKey('last_at')) {
      context.handle(
        _lastAtMeta,
        lastAt.isAcceptableOrUnknown(data['last_at']!, _lastAtMeta),
      );
    } else if (isInserting) {
      context.missing(_lastAtMeta);
    }
    if (data.containsKey('unread')) {
      context.handle(
        _unreadMeta,
        unread.isAcceptableOrUnknown(data['unread']!, _unreadMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Conversation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Conversation(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      hlc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hlc'],
      )!,
      deleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted'],
      )!,
      contactId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}contact_id'],
      ),
      channel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}channel'],
      )!,
      account: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account'],
      )!,
      mode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mode'],
      )!,
      externalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}external_id'],
      ),
      peer: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}peer'],
      )!,
      subject: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subject'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      followUp: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}follow_up'],
      ),
      jobId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}job_id'],
      ),
      lastAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_at'],
      )!,
      unread: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}unread'],
      )!,
    );
  }

  @override
  $ConversationsTable createAlias(String alias) {
    return $ConversationsTable(attachedDatabase, alias);
  }
}

class Conversation extends DataClass implements Insertable<Conversation> {
  final String id;
  final String hlc;
  final bool deleted;

  /// The person (career_contacts id); null while the sender is unknown and
  /// the thread waits in the Screener.
  final String? contactId;

  /// email | linkedin | bluesky | phone | in_person | other
  final String channel;

  /// The user's own account on that channel ('' when there is one only).
  final String account;

  /// api (sent and received by Udyoga) | manual (logged by the user) |
  /// import (from an export file)
  final String mode;

  /// The channel's own thread id (a Gmail thread, a Bluesky convo), so a
  /// later fetch or import adds to this thread.
  final String? externalId;

  /// Who the other side is as the channel gave it (an address or profile
  /// URL); names the sender of a Screener thread.
  final String peer;
  final String subject;

  /// draft | to_send | awaiting_reply | replied | follow_up | closed
  final String status;
  final String? followUp;
  final String? jobId;

  /// Time of the newest message, for sorting.
  final String lastAt;
  final int unread;
  const Conversation({
    required this.id,
    required this.hlc,
    required this.deleted,
    this.contactId,
    required this.channel,
    required this.account,
    required this.mode,
    this.externalId,
    required this.peer,
    required this.subject,
    required this.status,
    this.followUp,
    this.jobId,
    required this.lastAt,
    required this.unread,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['hlc'] = Variable<String>(hlc);
    map['deleted'] = Variable<bool>(deleted);
    if (!nullToAbsent || contactId != null) {
      map['contact_id'] = Variable<String>(contactId);
    }
    map['channel'] = Variable<String>(channel);
    map['account'] = Variable<String>(account);
    map['mode'] = Variable<String>(mode);
    if (!nullToAbsent || externalId != null) {
      map['external_id'] = Variable<String>(externalId);
    }
    map['peer'] = Variable<String>(peer);
    map['subject'] = Variable<String>(subject);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || followUp != null) {
      map['follow_up'] = Variable<String>(followUp);
    }
    if (!nullToAbsent || jobId != null) {
      map['job_id'] = Variable<String>(jobId);
    }
    map['last_at'] = Variable<String>(lastAt);
    map['unread'] = Variable<int>(unread);
    return map;
  }

  ConversationsCompanion toCompanion(bool nullToAbsent) {
    return ConversationsCompanion(
      id: Value(id),
      hlc: Value(hlc),
      deleted: Value(deleted),
      contactId: contactId == null && nullToAbsent
          ? const Value.absent()
          : Value(contactId),
      channel: Value(channel),
      account: Value(account),
      mode: Value(mode),
      externalId: externalId == null && nullToAbsent
          ? const Value.absent()
          : Value(externalId),
      peer: Value(peer),
      subject: Value(subject),
      status: Value(status),
      followUp: followUp == null && nullToAbsent
          ? const Value.absent()
          : Value(followUp),
      jobId: jobId == null && nullToAbsent
          ? const Value.absent()
          : Value(jobId),
      lastAt: Value(lastAt),
      unread: Value(unread),
    );
  }

  factory Conversation.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Conversation(
      id: serializer.fromJson<String>(json['id']),
      hlc: serializer.fromJson<String>(json['hlc']),
      deleted: serializer.fromJson<bool>(json['deleted']),
      contactId: serializer.fromJson<String?>(json['contactId']),
      channel: serializer.fromJson<String>(json['channel']),
      account: serializer.fromJson<String>(json['account']),
      mode: serializer.fromJson<String>(json['mode']),
      externalId: serializer.fromJson<String?>(json['externalId']),
      peer: serializer.fromJson<String>(json['peer']),
      subject: serializer.fromJson<String>(json['subject']),
      status: serializer.fromJson<String>(json['status']),
      followUp: serializer.fromJson<String?>(json['followUp']),
      jobId: serializer.fromJson<String?>(json['jobId']),
      lastAt: serializer.fromJson<String>(json['lastAt']),
      unread: serializer.fromJson<int>(json['unread']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'hlc': serializer.toJson<String>(hlc),
      'deleted': serializer.toJson<bool>(deleted),
      'contactId': serializer.toJson<String?>(contactId),
      'channel': serializer.toJson<String>(channel),
      'account': serializer.toJson<String>(account),
      'mode': serializer.toJson<String>(mode),
      'externalId': serializer.toJson<String?>(externalId),
      'peer': serializer.toJson<String>(peer),
      'subject': serializer.toJson<String>(subject),
      'status': serializer.toJson<String>(status),
      'followUp': serializer.toJson<String?>(followUp),
      'jobId': serializer.toJson<String?>(jobId),
      'lastAt': serializer.toJson<String>(lastAt),
      'unread': serializer.toJson<int>(unread),
    };
  }

  Conversation copyWith({
    String? id,
    String? hlc,
    bool? deleted,
    Value<String?> contactId = const Value.absent(),
    String? channel,
    String? account,
    String? mode,
    Value<String?> externalId = const Value.absent(),
    String? peer,
    String? subject,
    String? status,
    Value<String?> followUp = const Value.absent(),
    Value<String?> jobId = const Value.absent(),
    String? lastAt,
    int? unread,
  }) => Conversation(
    id: id ?? this.id,
    hlc: hlc ?? this.hlc,
    deleted: deleted ?? this.deleted,
    contactId: contactId.present ? contactId.value : this.contactId,
    channel: channel ?? this.channel,
    account: account ?? this.account,
    mode: mode ?? this.mode,
    externalId: externalId.present ? externalId.value : this.externalId,
    peer: peer ?? this.peer,
    subject: subject ?? this.subject,
    status: status ?? this.status,
    followUp: followUp.present ? followUp.value : this.followUp,
    jobId: jobId.present ? jobId.value : this.jobId,
    lastAt: lastAt ?? this.lastAt,
    unread: unread ?? this.unread,
  );
  Conversation copyWithCompanion(ConversationsCompanion data) {
    return Conversation(
      id: data.id.present ? data.id.value : this.id,
      hlc: data.hlc.present ? data.hlc.value : this.hlc,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      contactId: data.contactId.present ? data.contactId.value : this.contactId,
      channel: data.channel.present ? data.channel.value : this.channel,
      account: data.account.present ? data.account.value : this.account,
      mode: data.mode.present ? data.mode.value : this.mode,
      externalId: data.externalId.present
          ? data.externalId.value
          : this.externalId,
      peer: data.peer.present ? data.peer.value : this.peer,
      subject: data.subject.present ? data.subject.value : this.subject,
      status: data.status.present ? data.status.value : this.status,
      followUp: data.followUp.present ? data.followUp.value : this.followUp,
      jobId: data.jobId.present ? data.jobId.value : this.jobId,
      lastAt: data.lastAt.present ? data.lastAt.value : this.lastAt,
      unread: data.unread.present ? data.unread.value : this.unread,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Conversation(')
          ..write('id: $id, ')
          ..write('hlc: $hlc, ')
          ..write('deleted: $deleted, ')
          ..write('contactId: $contactId, ')
          ..write('channel: $channel, ')
          ..write('account: $account, ')
          ..write('mode: $mode, ')
          ..write('externalId: $externalId, ')
          ..write('peer: $peer, ')
          ..write('subject: $subject, ')
          ..write('status: $status, ')
          ..write('followUp: $followUp, ')
          ..write('jobId: $jobId, ')
          ..write('lastAt: $lastAt, ')
          ..write('unread: $unread')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    hlc,
    deleted,
    contactId,
    channel,
    account,
    mode,
    externalId,
    peer,
    subject,
    status,
    followUp,
    jobId,
    lastAt,
    unread,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Conversation &&
          other.id == this.id &&
          other.hlc == this.hlc &&
          other.deleted == this.deleted &&
          other.contactId == this.contactId &&
          other.channel == this.channel &&
          other.account == this.account &&
          other.mode == this.mode &&
          other.externalId == this.externalId &&
          other.peer == this.peer &&
          other.subject == this.subject &&
          other.status == this.status &&
          other.followUp == this.followUp &&
          other.jobId == this.jobId &&
          other.lastAt == this.lastAt &&
          other.unread == this.unread);
}

class ConversationsCompanion extends UpdateCompanion<Conversation> {
  final Value<String> id;
  final Value<String> hlc;
  final Value<bool> deleted;
  final Value<String?> contactId;
  final Value<String> channel;
  final Value<String> account;
  final Value<String> mode;
  final Value<String?> externalId;
  final Value<String> peer;
  final Value<String> subject;
  final Value<String> status;
  final Value<String?> followUp;
  final Value<String?> jobId;
  final Value<String> lastAt;
  final Value<int> unread;
  final Value<int> rowid;
  const ConversationsCompanion({
    this.id = const Value.absent(),
    this.hlc = const Value.absent(),
    this.deleted = const Value.absent(),
    this.contactId = const Value.absent(),
    this.channel = const Value.absent(),
    this.account = const Value.absent(),
    this.mode = const Value.absent(),
    this.externalId = const Value.absent(),
    this.peer = const Value.absent(),
    this.subject = const Value.absent(),
    this.status = const Value.absent(),
    this.followUp = const Value.absent(),
    this.jobId = const Value.absent(),
    this.lastAt = const Value.absent(),
    this.unread = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ConversationsCompanion.insert({
    required String id,
    this.hlc = const Value.absent(),
    this.deleted = const Value.absent(),
    this.contactId = const Value.absent(),
    required String channel,
    this.account = const Value.absent(),
    this.mode = const Value.absent(),
    this.externalId = const Value.absent(),
    this.peer = const Value.absent(),
    this.subject = const Value.absent(),
    this.status = const Value.absent(),
    this.followUp = const Value.absent(),
    this.jobId = const Value.absent(),
    required String lastAt,
    this.unread = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       channel = Value(channel),
       lastAt = Value(lastAt);
  static Insertable<Conversation> custom({
    Expression<String>? id,
    Expression<String>? hlc,
    Expression<bool>? deleted,
    Expression<String>? contactId,
    Expression<String>? channel,
    Expression<String>? account,
    Expression<String>? mode,
    Expression<String>? externalId,
    Expression<String>? peer,
    Expression<String>? subject,
    Expression<String>? status,
    Expression<String>? followUp,
    Expression<String>? jobId,
    Expression<String>? lastAt,
    Expression<int>? unread,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (hlc != null) 'hlc': hlc,
      if (deleted != null) 'deleted': deleted,
      if (contactId != null) 'contact_id': contactId,
      if (channel != null) 'channel': channel,
      if (account != null) 'account': account,
      if (mode != null) 'mode': mode,
      if (externalId != null) 'external_id': externalId,
      if (peer != null) 'peer': peer,
      if (subject != null) 'subject': subject,
      if (status != null) 'status': status,
      if (followUp != null) 'follow_up': followUp,
      if (jobId != null) 'job_id': jobId,
      if (lastAt != null) 'last_at': lastAt,
      if (unread != null) 'unread': unread,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ConversationsCompanion copyWith({
    Value<String>? id,
    Value<String>? hlc,
    Value<bool>? deleted,
    Value<String?>? contactId,
    Value<String>? channel,
    Value<String>? account,
    Value<String>? mode,
    Value<String?>? externalId,
    Value<String>? peer,
    Value<String>? subject,
    Value<String>? status,
    Value<String?>? followUp,
    Value<String?>? jobId,
    Value<String>? lastAt,
    Value<int>? unread,
    Value<int>? rowid,
  }) {
    return ConversationsCompanion(
      id: id ?? this.id,
      hlc: hlc ?? this.hlc,
      deleted: deleted ?? this.deleted,
      contactId: contactId ?? this.contactId,
      channel: channel ?? this.channel,
      account: account ?? this.account,
      mode: mode ?? this.mode,
      externalId: externalId ?? this.externalId,
      peer: peer ?? this.peer,
      subject: subject ?? this.subject,
      status: status ?? this.status,
      followUp: followUp ?? this.followUp,
      jobId: jobId ?? this.jobId,
      lastAt: lastAt ?? this.lastAt,
      unread: unread ?? this.unread,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (hlc.present) {
      map['hlc'] = Variable<String>(hlc.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (contactId.present) {
      map['contact_id'] = Variable<String>(contactId.value);
    }
    if (channel.present) {
      map['channel'] = Variable<String>(channel.value);
    }
    if (account.present) {
      map['account'] = Variable<String>(account.value);
    }
    if (mode.present) {
      map['mode'] = Variable<String>(mode.value);
    }
    if (externalId.present) {
      map['external_id'] = Variable<String>(externalId.value);
    }
    if (peer.present) {
      map['peer'] = Variable<String>(peer.value);
    }
    if (subject.present) {
      map['subject'] = Variable<String>(subject.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (followUp.present) {
      map['follow_up'] = Variable<String>(followUp.value);
    }
    if (jobId.present) {
      map['job_id'] = Variable<String>(jobId.value);
    }
    if (lastAt.present) {
      map['last_at'] = Variable<String>(lastAt.value);
    }
    if (unread.present) {
      map['unread'] = Variable<int>(unread.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ConversationsCompanion(')
          ..write('id: $id, ')
          ..write('hlc: $hlc, ')
          ..write('deleted: $deleted, ')
          ..write('contactId: $contactId, ')
          ..write('channel: $channel, ')
          ..write('account: $account, ')
          ..write('mode: $mode, ')
          ..write('externalId: $externalId, ')
          ..write('peer: $peer, ')
          ..write('subject: $subject, ')
          ..write('status: $status, ')
          ..write('followUp: $followUp, ')
          ..write('jobId: $jobId, ')
          ..write('lastAt: $lastAt, ')
          ..write('unread: $unread, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MessagesTable extends Messages
    with TableInfo<$MessagesTable, ThreadMessage> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MessagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hlcMeta = const VerificationMeta('hlc');
  @override
  late final GeneratedColumn<String> hlc = GeneratedColumn<String>(
    'hlc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _deletedMeta = const VerificationMeta(
    'deleted',
  );
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _conversationIdMeta = const VerificationMeta(
    'conversationId',
  );
  @override
  late final GeneratedColumn<String> conversationId = GeneratedColumn<String>(
    'conversation_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _directionMeta = const VerificationMeta(
    'direction',
  );
  @override
  late final GeneratedColumn<String> direction = GeneratedColumn<String>(
    'direction',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _sentAtMeta = const VerificationMeta('sentAt');
  @override
  late final GeneratedColumn<String> sentAt = GeneratedColumn<String>(
    'sent_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('manual'),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('logged'),
  );
  static const VerificationMeta _externalIdMeta = const VerificationMeta(
    'externalId',
  );
  @override
  late final GeneratedColumn<String> externalId = GeneratedColumn<String>(
    'external_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _inReplyToMeta = const VerificationMeta(
    'inReplyTo',
  );
  @override
  late final GeneratedColumn<String> inReplyTo = GeneratedColumn<String>(
    'in_reply_to',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _draftOfMeta = const VerificationMeta(
    'draftOf',
  );
  @override
  late final GeneratedColumn<String> draftOf = GeneratedColumn<String>(
    'draft_of',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    hlc,
    deleted,
    conversationId,
    direction,
    body,
    sentAt,
    source,
    status,
    externalId,
    inReplyTo,
    draftOf,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'career_messages';
  @override
  VerificationContext validateIntegrity(
    Insertable<ThreadMessage> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('hlc')) {
      context.handle(
        _hlcMeta,
        hlc.isAcceptableOrUnknown(data['hlc']!, _hlcMeta),
      );
    }
    if (data.containsKey('deleted')) {
      context.handle(
        _deletedMeta,
        deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta),
      );
    }
    if (data.containsKey('conversation_id')) {
      context.handle(
        _conversationIdMeta,
        conversationId.isAcceptableOrUnknown(
          data['conversation_id']!,
          _conversationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_conversationIdMeta);
    }
    if (data.containsKey('direction')) {
      context.handle(
        _directionMeta,
        direction.isAcceptableOrUnknown(data['direction']!, _directionMeta),
      );
    } else if (isInserting) {
      context.missing(_directionMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    }
    if (data.containsKey('sent_at')) {
      context.handle(
        _sentAtMeta,
        sentAt.isAcceptableOrUnknown(data['sent_at']!, _sentAtMeta),
      );
    } else if (isInserting) {
      context.missing(_sentAtMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('external_id')) {
      context.handle(
        _externalIdMeta,
        externalId.isAcceptableOrUnknown(data['external_id']!, _externalIdMeta),
      );
    }
    if (data.containsKey('in_reply_to')) {
      context.handle(
        _inReplyToMeta,
        inReplyTo.isAcceptableOrUnknown(data['in_reply_to']!, _inReplyToMeta),
      );
    }
    if (data.containsKey('draft_of')) {
      context.handle(
        _draftOfMeta,
        draftOf.isAcceptableOrUnknown(data['draft_of']!, _draftOfMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ThreadMessage map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ThreadMessage(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      hlc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hlc'],
      )!,
      deleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted'],
      )!,
      conversationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}conversation_id'],
      )!,
      direction: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}direction'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      )!,
      sentAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sent_at'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      externalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}external_id'],
      ),
      inReplyTo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}in_reply_to'],
      ),
      draftOf: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}draft_of'],
      ),
    );
  }

  @override
  $MessagesTable createAlias(String alias) {
    return $MessagesTable(attachedDatabase, alias);
  }
}

class ThreadMessage extends DataClass implements Insertable<ThreadMessage> {
  final String id;
  final String hlc;
  final bool deleted;
  final String conversationId;

  /// out | in | note
  final String direction;

  /// Plain text.
  final String body;

  /// When it was sent; for a logged message, when the user says it was.
  final String sentAt;

  /// api | manual | import | ai_draft
  final String source;

  /// logged | invite (a LinkedIn connection note, logged) | draft | queued |
  /// sent | failed | received
  final String status;

  /// The provider's message id (Message-ID...), so nothing is stored twice.
  final String? externalId;
  final String? inReplyTo;

  /// The AI draft this message came from.
  final String? draftOf;
  const ThreadMessage({
    required this.id,
    required this.hlc,
    required this.deleted,
    required this.conversationId,
    required this.direction,
    required this.body,
    required this.sentAt,
    required this.source,
    required this.status,
    this.externalId,
    this.inReplyTo,
    this.draftOf,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['hlc'] = Variable<String>(hlc);
    map['deleted'] = Variable<bool>(deleted);
    map['conversation_id'] = Variable<String>(conversationId);
    map['direction'] = Variable<String>(direction);
    map['body'] = Variable<String>(body);
    map['sent_at'] = Variable<String>(sentAt);
    map['source'] = Variable<String>(source);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || externalId != null) {
      map['external_id'] = Variable<String>(externalId);
    }
    if (!nullToAbsent || inReplyTo != null) {
      map['in_reply_to'] = Variable<String>(inReplyTo);
    }
    if (!nullToAbsent || draftOf != null) {
      map['draft_of'] = Variable<String>(draftOf);
    }
    return map;
  }

  MessagesCompanion toCompanion(bool nullToAbsent) {
    return MessagesCompanion(
      id: Value(id),
      hlc: Value(hlc),
      deleted: Value(deleted),
      conversationId: Value(conversationId),
      direction: Value(direction),
      body: Value(body),
      sentAt: Value(sentAt),
      source: Value(source),
      status: Value(status),
      externalId: externalId == null && nullToAbsent
          ? const Value.absent()
          : Value(externalId),
      inReplyTo: inReplyTo == null && nullToAbsent
          ? const Value.absent()
          : Value(inReplyTo),
      draftOf: draftOf == null && nullToAbsent
          ? const Value.absent()
          : Value(draftOf),
    );
  }

  factory ThreadMessage.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ThreadMessage(
      id: serializer.fromJson<String>(json['id']),
      hlc: serializer.fromJson<String>(json['hlc']),
      deleted: serializer.fromJson<bool>(json['deleted']),
      conversationId: serializer.fromJson<String>(json['conversationId']),
      direction: serializer.fromJson<String>(json['direction']),
      body: serializer.fromJson<String>(json['body']),
      sentAt: serializer.fromJson<String>(json['sentAt']),
      source: serializer.fromJson<String>(json['source']),
      status: serializer.fromJson<String>(json['status']),
      externalId: serializer.fromJson<String?>(json['externalId']),
      inReplyTo: serializer.fromJson<String?>(json['inReplyTo']),
      draftOf: serializer.fromJson<String?>(json['draftOf']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'hlc': serializer.toJson<String>(hlc),
      'deleted': serializer.toJson<bool>(deleted),
      'conversationId': serializer.toJson<String>(conversationId),
      'direction': serializer.toJson<String>(direction),
      'body': serializer.toJson<String>(body),
      'sentAt': serializer.toJson<String>(sentAt),
      'source': serializer.toJson<String>(source),
      'status': serializer.toJson<String>(status),
      'externalId': serializer.toJson<String?>(externalId),
      'inReplyTo': serializer.toJson<String?>(inReplyTo),
      'draftOf': serializer.toJson<String?>(draftOf),
    };
  }

  ThreadMessage copyWith({
    String? id,
    String? hlc,
    bool? deleted,
    String? conversationId,
    String? direction,
    String? body,
    String? sentAt,
    String? source,
    String? status,
    Value<String?> externalId = const Value.absent(),
    Value<String?> inReplyTo = const Value.absent(),
    Value<String?> draftOf = const Value.absent(),
  }) => ThreadMessage(
    id: id ?? this.id,
    hlc: hlc ?? this.hlc,
    deleted: deleted ?? this.deleted,
    conversationId: conversationId ?? this.conversationId,
    direction: direction ?? this.direction,
    body: body ?? this.body,
    sentAt: sentAt ?? this.sentAt,
    source: source ?? this.source,
    status: status ?? this.status,
    externalId: externalId.present ? externalId.value : this.externalId,
    inReplyTo: inReplyTo.present ? inReplyTo.value : this.inReplyTo,
    draftOf: draftOf.present ? draftOf.value : this.draftOf,
  );
  ThreadMessage copyWithCompanion(MessagesCompanion data) {
    return ThreadMessage(
      id: data.id.present ? data.id.value : this.id,
      hlc: data.hlc.present ? data.hlc.value : this.hlc,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      conversationId: data.conversationId.present
          ? data.conversationId.value
          : this.conversationId,
      direction: data.direction.present ? data.direction.value : this.direction,
      body: data.body.present ? data.body.value : this.body,
      sentAt: data.sentAt.present ? data.sentAt.value : this.sentAt,
      source: data.source.present ? data.source.value : this.source,
      status: data.status.present ? data.status.value : this.status,
      externalId: data.externalId.present
          ? data.externalId.value
          : this.externalId,
      inReplyTo: data.inReplyTo.present ? data.inReplyTo.value : this.inReplyTo,
      draftOf: data.draftOf.present ? data.draftOf.value : this.draftOf,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ThreadMessage(')
          ..write('id: $id, ')
          ..write('hlc: $hlc, ')
          ..write('deleted: $deleted, ')
          ..write('conversationId: $conversationId, ')
          ..write('direction: $direction, ')
          ..write('body: $body, ')
          ..write('sentAt: $sentAt, ')
          ..write('source: $source, ')
          ..write('status: $status, ')
          ..write('externalId: $externalId, ')
          ..write('inReplyTo: $inReplyTo, ')
          ..write('draftOf: $draftOf')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    hlc,
    deleted,
    conversationId,
    direction,
    body,
    sentAt,
    source,
    status,
    externalId,
    inReplyTo,
    draftOf,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ThreadMessage &&
          other.id == this.id &&
          other.hlc == this.hlc &&
          other.deleted == this.deleted &&
          other.conversationId == this.conversationId &&
          other.direction == this.direction &&
          other.body == this.body &&
          other.sentAt == this.sentAt &&
          other.source == this.source &&
          other.status == this.status &&
          other.externalId == this.externalId &&
          other.inReplyTo == this.inReplyTo &&
          other.draftOf == this.draftOf);
}

class MessagesCompanion extends UpdateCompanion<ThreadMessage> {
  final Value<String> id;
  final Value<String> hlc;
  final Value<bool> deleted;
  final Value<String> conversationId;
  final Value<String> direction;
  final Value<String> body;
  final Value<String> sentAt;
  final Value<String> source;
  final Value<String> status;
  final Value<String?> externalId;
  final Value<String?> inReplyTo;
  final Value<String?> draftOf;
  final Value<int> rowid;
  const MessagesCompanion({
    this.id = const Value.absent(),
    this.hlc = const Value.absent(),
    this.deleted = const Value.absent(),
    this.conversationId = const Value.absent(),
    this.direction = const Value.absent(),
    this.body = const Value.absent(),
    this.sentAt = const Value.absent(),
    this.source = const Value.absent(),
    this.status = const Value.absent(),
    this.externalId = const Value.absent(),
    this.inReplyTo = const Value.absent(),
    this.draftOf = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MessagesCompanion.insert({
    required String id,
    this.hlc = const Value.absent(),
    this.deleted = const Value.absent(),
    required String conversationId,
    required String direction,
    this.body = const Value.absent(),
    required String sentAt,
    this.source = const Value.absent(),
    this.status = const Value.absent(),
    this.externalId = const Value.absent(),
    this.inReplyTo = const Value.absent(),
    this.draftOf = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       conversationId = Value(conversationId),
       direction = Value(direction),
       sentAt = Value(sentAt);
  static Insertable<ThreadMessage> custom({
    Expression<String>? id,
    Expression<String>? hlc,
    Expression<bool>? deleted,
    Expression<String>? conversationId,
    Expression<String>? direction,
    Expression<String>? body,
    Expression<String>? sentAt,
    Expression<String>? source,
    Expression<String>? status,
    Expression<String>? externalId,
    Expression<String>? inReplyTo,
    Expression<String>? draftOf,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (hlc != null) 'hlc': hlc,
      if (deleted != null) 'deleted': deleted,
      if (conversationId != null) 'conversation_id': conversationId,
      if (direction != null) 'direction': direction,
      if (body != null) 'body': body,
      if (sentAt != null) 'sent_at': sentAt,
      if (source != null) 'source': source,
      if (status != null) 'status': status,
      if (externalId != null) 'external_id': externalId,
      if (inReplyTo != null) 'in_reply_to': inReplyTo,
      if (draftOf != null) 'draft_of': draftOf,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MessagesCompanion copyWith({
    Value<String>? id,
    Value<String>? hlc,
    Value<bool>? deleted,
    Value<String>? conversationId,
    Value<String>? direction,
    Value<String>? body,
    Value<String>? sentAt,
    Value<String>? source,
    Value<String>? status,
    Value<String?>? externalId,
    Value<String?>? inReplyTo,
    Value<String?>? draftOf,
    Value<int>? rowid,
  }) {
    return MessagesCompanion(
      id: id ?? this.id,
      hlc: hlc ?? this.hlc,
      deleted: deleted ?? this.deleted,
      conversationId: conversationId ?? this.conversationId,
      direction: direction ?? this.direction,
      body: body ?? this.body,
      sentAt: sentAt ?? this.sentAt,
      source: source ?? this.source,
      status: status ?? this.status,
      externalId: externalId ?? this.externalId,
      inReplyTo: inReplyTo ?? this.inReplyTo,
      draftOf: draftOf ?? this.draftOf,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (hlc.present) {
      map['hlc'] = Variable<String>(hlc.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (conversationId.present) {
      map['conversation_id'] = Variable<String>(conversationId.value);
    }
    if (direction.present) {
      map['direction'] = Variable<String>(direction.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (sentAt.present) {
      map['sent_at'] = Variable<String>(sentAt.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (externalId.present) {
      map['external_id'] = Variable<String>(externalId.value);
    }
    if (inReplyTo.present) {
      map['in_reply_to'] = Variable<String>(inReplyTo.value);
    }
    if (draftOf.present) {
      map['draft_of'] = Variable<String>(draftOf.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MessagesCompanion(')
          ..write('id: $id, ')
          ..write('hlc: $hlc, ')
          ..write('deleted: $deleted, ')
          ..write('conversationId: $conversationId, ')
          ..write('direction: $direction, ')
          ..write('body: $body, ')
          ..write('sentAt: $sentAt, ')
          ..write('source: $source, ')
          ..write('status: $status, ')
          ..write('externalId: $externalId, ')
          ..write('inReplyTo: $inReplyTo, ')
          ..write('draftOf: $draftOf, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CareerPostsTable extends CareerPosts
    with TableInfo<$CareerPostsTable, PlannedPost> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CareerPostsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hlcMeta = const VerificationMeta('hlc');
  @override
  late final GeneratedColumn<String> hlc = GeneratedColumn<String>(
    'hlc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _deletedMeta = const VerificationMeta(
    'deleted',
  );
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _channelMeta = const VerificationMeta(
    'channel',
  );
  @override
  late final GeneratedColumn<String> channel = GeneratedColumn<String>(
    'channel',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('linkedin'),
  );
  static const VerificationMeta _atMeta = const VerificationMeta('at');
  @override
  late final GeneratedColumn<String> at = GeneratedColumn<String>(
    'at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _topicMeta = const VerificationMeta('topic');
  @override
  late final GeneratedColumn<String> topic = GeneratedColumn<String>(
    'topic',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _humanizedMeta = const VerificationMeta(
    'humanized',
  );
  @override
  late final GeneratedColumn<String> humanized = GeneratedColumn<String>(
    'humanized',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('planned'),
  );
  static const VerificationMeta _postUrlMeta = const VerificationMeta(
    'postUrl',
  );
  @override
  late final GeneratedColumn<String> postUrl = GeneratedColumn<String>(
    'post_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _postedAtMeta = const VerificationMeta(
    'postedAt',
  );
  @override
  late final GeneratedColumn<String> postedAt = GeneratedColumn<String>(
    'posted_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    hlc,
    deleted,
    channel,
    at,
    topic,
    body,
    humanized,
    status,
    postUrl,
    postedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'career_posts';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlannedPost> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('hlc')) {
      context.handle(
        _hlcMeta,
        hlc.isAcceptableOrUnknown(data['hlc']!, _hlcMeta),
      );
    }
    if (data.containsKey('deleted')) {
      context.handle(
        _deletedMeta,
        deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta),
      );
    }
    if (data.containsKey('channel')) {
      context.handle(
        _channelMeta,
        channel.isAcceptableOrUnknown(data['channel']!, _channelMeta),
      );
    }
    if (data.containsKey('at')) {
      context.handle(_atMeta, at.isAcceptableOrUnknown(data['at']!, _atMeta));
    } else if (isInserting) {
      context.missing(_atMeta);
    }
    if (data.containsKey('topic')) {
      context.handle(
        _topicMeta,
        topic.isAcceptableOrUnknown(data['topic']!, _topicMeta),
      );
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    }
    if (data.containsKey('humanized')) {
      context.handle(
        _humanizedMeta,
        humanized.isAcceptableOrUnknown(data['humanized']!, _humanizedMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('post_url')) {
      context.handle(
        _postUrlMeta,
        postUrl.isAcceptableOrUnknown(data['post_url']!, _postUrlMeta),
      );
    }
    if (data.containsKey('posted_at')) {
      context.handle(
        _postedAtMeta,
        postedAt.isAcceptableOrUnknown(data['posted_at']!, _postedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlannedPost map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlannedPost(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      hlc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hlc'],
      )!,
      deleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted'],
      )!,
      channel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}channel'],
      )!,
      at: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}at'],
      )!,
      topic: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}topic'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      )!,
      humanized: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}humanized'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      postUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}post_url'],
      )!,
      postedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}posted_at'],
      ),
    );
  }

  @override
  $CareerPostsTable createAlias(String alias) {
    return $CareerPostsTable(attachedDatabase, alias);
  }
}

class PlannedPost extends DataClass implements Insertable<PlannedPost> {
  final String id;
  final String hlc;
  final bool deleted;

  /// linkedin | bluesky
  final String channel;

  /// The slot, local time (YYYY-MM-DDTHH:mm).
  final String at;

  /// What it is about, before there is a draft.
  final String topic;
  final String body;

  /// The draft after the humanizer, when the user ran it.
  final String humanized;

  /// planned | posted | skipped ("due" is a planned post whose time has
  /// come).
  final String status;

  /// The post's address, pasted by the user or given by Bluesky.
  final String postUrl;
  final String? postedAt;
  const PlannedPost({
    required this.id,
    required this.hlc,
    required this.deleted,
    required this.channel,
    required this.at,
    required this.topic,
    required this.body,
    required this.humanized,
    required this.status,
    required this.postUrl,
    this.postedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['hlc'] = Variable<String>(hlc);
    map['deleted'] = Variable<bool>(deleted);
    map['channel'] = Variable<String>(channel);
    map['at'] = Variable<String>(at);
    map['topic'] = Variable<String>(topic);
    map['body'] = Variable<String>(body);
    map['humanized'] = Variable<String>(humanized);
    map['status'] = Variable<String>(status);
    map['post_url'] = Variable<String>(postUrl);
    if (!nullToAbsent || postedAt != null) {
      map['posted_at'] = Variable<String>(postedAt);
    }
    return map;
  }

  CareerPostsCompanion toCompanion(bool nullToAbsent) {
    return CareerPostsCompanion(
      id: Value(id),
      hlc: Value(hlc),
      deleted: Value(deleted),
      channel: Value(channel),
      at: Value(at),
      topic: Value(topic),
      body: Value(body),
      humanized: Value(humanized),
      status: Value(status),
      postUrl: Value(postUrl),
      postedAt: postedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(postedAt),
    );
  }

  factory PlannedPost.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlannedPost(
      id: serializer.fromJson<String>(json['id']),
      hlc: serializer.fromJson<String>(json['hlc']),
      deleted: serializer.fromJson<bool>(json['deleted']),
      channel: serializer.fromJson<String>(json['channel']),
      at: serializer.fromJson<String>(json['at']),
      topic: serializer.fromJson<String>(json['topic']),
      body: serializer.fromJson<String>(json['body']),
      humanized: serializer.fromJson<String>(json['humanized']),
      status: serializer.fromJson<String>(json['status']),
      postUrl: serializer.fromJson<String>(json['postUrl']),
      postedAt: serializer.fromJson<String?>(json['postedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'hlc': serializer.toJson<String>(hlc),
      'deleted': serializer.toJson<bool>(deleted),
      'channel': serializer.toJson<String>(channel),
      'at': serializer.toJson<String>(at),
      'topic': serializer.toJson<String>(topic),
      'body': serializer.toJson<String>(body),
      'humanized': serializer.toJson<String>(humanized),
      'status': serializer.toJson<String>(status),
      'postUrl': serializer.toJson<String>(postUrl),
      'postedAt': serializer.toJson<String?>(postedAt),
    };
  }

  PlannedPost copyWith({
    String? id,
    String? hlc,
    bool? deleted,
    String? channel,
    String? at,
    String? topic,
    String? body,
    String? humanized,
    String? status,
    String? postUrl,
    Value<String?> postedAt = const Value.absent(),
  }) => PlannedPost(
    id: id ?? this.id,
    hlc: hlc ?? this.hlc,
    deleted: deleted ?? this.deleted,
    channel: channel ?? this.channel,
    at: at ?? this.at,
    topic: topic ?? this.topic,
    body: body ?? this.body,
    humanized: humanized ?? this.humanized,
    status: status ?? this.status,
    postUrl: postUrl ?? this.postUrl,
    postedAt: postedAt.present ? postedAt.value : this.postedAt,
  );
  PlannedPost copyWithCompanion(CareerPostsCompanion data) {
    return PlannedPost(
      id: data.id.present ? data.id.value : this.id,
      hlc: data.hlc.present ? data.hlc.value : this.hlc,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      channel: data.channel.present ? data.channel.value : this.channel,
      at: data.at.present ? data.at.value : this.at,
      topic: data.topic.present ? data.topic.value : this.topic,
      body: data.body.present ? data.body.value : this.body,
      humanized: data.humanized.present ? data.humanized.value : this.humanized,
      status: data.status.present ? data.status.value : this.status,
      postUrl: data.postUrl.present ? data.postUrl.value : this.postUrl,
      postedAt: data.postedAt.present ? data.postedAt.value : this.postedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlannedPost(')
          ..write('id: $id, ')
          ..write('hlc: $hlc, ')
          ..write('deleted: $deleted, ')
          ..write('channel: $channel, ')
          ..write('at: $at, ')
          ..write('topic: $topic, ')
          ..write('body: $body, ')
          ..write('humanized: $humanized, ')
          ..write('status: $status, ')
          ..write('postUrl: $postUrl, ')
          ..write('postedAt: $postedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    hlc,
    deleted,
    channel,
    at,
    topic,
    body,
    humanized,
    status,
    postUrl,
    postedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlannedPost &&
          other.id == this.id &&
          other.hlc == this.hlc &&
          other.deleted == this.deleted &&
          other.channel == this.channel &&
          other.at == this.at &&
          other.topic == this.topic &&
          other.body == this.body &&
          other.humanized == this.humanized &&
          other.status == this.status &&
          other.postUrl == this.postUrl &&
          other.postedAt == this.postedAt);
}

class CareerPostsCompanion extends UpdateCompanion<PlannedPost> {
  final Value<String> id;
  final Value<String> hlc;
  final Value<bool> deleted;
  final Value<String> channel;
  final Value<String> at;
  final Value<String> topic;
  final Value<String> body;
  final Value<String> humanized;
  final Value<String> status;
  final Value<String> postUrl;
  final Value<String?> postedAt;
  final Value<int> rowid;
  const CareerPostsCompanion({
    this.id = const Value.absent(),
    this.hlc = const Value.absent(),
    this.deleted = const Value.absent(),
    this.channel = const Value.absent(),
    this.at = const Value.absent(),
    this.topic = const Value.absent(),
    this.body = const Value.absent(),
    this.humanized = const Value.absent(),
    this.status = const Value.absent(),
    this.postUrl = const Value.absent(),
    this.postedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CareerPostsCompanion.insert({
    required String id,
    this.hlc = const Value.absent(),
    this.deleted = const Value.absent(),
    this.channel = const Value.absent(),
    required String at,
    this.topic = const Value.absent(),
    this.body = const Value.absent(),
    this.humanized = const Value.absent(),
    this.status = const Value.absent(),
    this.postUrl = const Value.absent(),
    this.postedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       at = Value(at);
  static Insertable<PlannedPost> custom({
    Expression<String>? id,
    Expression<String>? hlc,
    Expression<bool>? deleted,
    Expression<String>? channel,
    Expression<String>? at,
    Expression<String>? topic,
    Expression<String>? body,
    Expression<String>? humanized,
    Expression<String>? status,
    Expression<String>? postUrl,
    Expression<String>? postedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (hlc != null) 'hlc': hlc,
      if (deleted != null) 'deleted': deleted,
      if (channel != null) 'channel': channel,
      if (at != null) 'at': at,
      if (topic != null) 'topic': topic,
      if (body != null) 'body': body,
      if (humanized != null) 'humanized': humanized,
      if (status != null) 'status': status,
      if (postUrl != null) 'post_url': postUrl,
      if (postedAt != null) 'posted_at': postedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CareerPostsCompanion copyWith({
    Value<String>? id,
    Value<String>? hlc,
    Value<bool>? deleted,
    Value<String>? channel,
    Value<String>? at,
    Value<String>? topic,
    Value<String>? body,
    Value<String>? humanized,
    Value<String>? status,
    Value<String>? postUrl,
    Value<String?>? postedAt,
    Value<int>? rowid,
  }) {
    return CareerPostsCompanion(
      id: id ?? this.id,
      hlc: hlc ?? this.hlc,
      deleted: deleted ?? this.deleted,
      channel: channel ?? this.channel,
      at: at ?? this.at,
      topic: topic ?? this.topic,
      body: body ?? this.body,
      humanized: humanized ?? this.humanized,
      status: status ?? this.status,
      postUrl: postUrl ?? this.postUrl,
      postedAt: postedAt ?? this.postedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (hlc.present) {
      map['hlc'] = Variable<String>(hlc.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (channel.present) {
      map['channel'] = Variable<String>(channel.value);
    }
    if (at.present) {
      map['at'] = Variable<String>(at.value);
    }
    if (topic.present) {
      map['topic'] = Variable<String>(topic.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (humanized.present) {
      map['humanized'] = Variable<String>(humanized.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (postUrl.present) {
      map['post_url'] = Variable<String>(postUrl.value);
    }
    if (postedAt.present) {
      map['posted_at'] = Variable<String>(postedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CareerPostsCompanion(')
          ..write('id: $id, ')
          ..write('hlc: $hlc, ')
          ..write('deleted: $deleted, ')
          ..write('channel: $channel, ')
          ..write('at: $at, ')
          ..write('topic: $topic, ')
          ..write('body: $body, ')
          ..write('humanized: $humanized, ')
          ..write('status: $status, ')
          ..write('postUrl: $postUrl, ')
          ..write('postedAt: $postedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CareerTracksTable extends CareerTracks
    with TableInfo<$CareerTracksTable, RouteTrack> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CareerTracksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hlcMeta = const VerificationMeta('hlc');
  @override
  late final GeneratedColumn<String> hlc = GeneratedColumn<String>(
    'hlc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _deletedMeta = const VerificationMeta(
    'deleted',
  );
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _countryMeta = const VerificationMeta(
    'country',
  );
  @override
  late final GeneratedColumn<String> country = GeneratedColumn<String>(
    'country',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _routeIdMeta = const VerificationMeta(
    'routeId',
  );
  @override
  late final GeneratedColumn<String> routeId = GeneratedColumn<String>(
    'route_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('active'),
  );
  static const VerificationMeta _triggerMeta = const VerificationMeta(
    'trigger',
  );
  @override
  late final GeneratedColumn<String> trigger = GeneratedColumn<String>(
    'trigger',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _milestonesMeta = const VerificationMeta(
    'milestones',
  );
  @override
  late final GeneratedColumn<String> milestones = GeneratedColumn<String>(
    'milestones',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _addedMeta = const VerificationMeta('added');
  @override
  late final GeneratedColumn<String> added = GeneratedColumn<String>(
    'added',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    hlc,
    deleted,
    country,
    routeId,
    title,
    status,
    trigger,
    milestones,
    notes,
    added,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'career_tracks';
  @override
  VerificationContext validateIntegrity(
    Insertable<RouteTrack> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('hlc')) {
      context.handle(
        _hlcMeta,
        hlc.isAcceptableOrUnknown(data['hlc']!, _hlcMeta),
      );
    }
    if (data.containsKey('deleted')) {
      context.handle(
        _deletedMeta,
        deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta),
      );
    }
    if (data.containsKey('country')) {
      context.handle(
        _countryMeta,
        country.isAcceptableOrUnknown(data['country']!, _countryMeta),
      );
    } else if (isInserting) {
      context.missing(_countryMeta);
    }
    if (data.containsKey('route_id')) {
      context.handle(
        _routeIdMeta,
        routeId.isAcceptableOrUnknown(data['route_id']!, _routeIdMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('trigger')) {
      context.handle(
        _triggerMeta,
        trigger.isAcceptableOrUnknown(data['trigger']!, _triggerMeta),
      );
    }
    if (data.containsKey('milestones')) {
      context.handle(
        _milestonesMeta,
        milestones.isAcceptableOrUnknown(data['milestones']!, _milestonesMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('added')) {
      context.handle(
        _addedMeta,
        added.isAcceptableOrUnknown(data['added']!, _addedMeta),
      );
    } else if (isInserting) {
      context.missing(_addedMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RouteTrack map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RouteTrack(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      hlc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hlc'],
      )!,
      deleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted'],
      )!,
      country: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}country'],
      )!,
      routeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}route_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      trigger: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}trigger'],
      )!,
      milestones: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}milestones'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      )!,
      added: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}added'],
      )!,
    );
  }

  @override
  $CareerTracksTable createAlias(String alias) {
    return $CareerTracksTable(attachedDatabase, alias);
  }
}

class RouteTrack extends DataClass implements Insertable<RouteTrack> {
  final String id;
  final String hlc;
  final bool deleted;

  /// ISO alpha-2.
  final String country;

  /// The route's id from the route tables ("gb.skilled-worker"), or ''.
  final String routeId;
  final String title;

  /// active | paused | done | dropped
  final String status;

  /// What starts or switches this track ("a sponsored offer at £41,700").
  final String trigger;

  /// JSON list of {id, title, due (yyyy-MM-dd or null), done (yyyy-MM-dd or null), todo (row id or null)}.
  final String milestones;
  final String notes;
  final String added;
  const RouteTrack({
    required this.id,
    required this.hlc,
    required this.deleted,
    required this.country,
    required this.routeId,
    required this.title,
    required this.status,
    required this.trigger,
    required this.milestones,
    required this.notes,
    required this.added,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['hlc'] = Variable<String>(hlc);
    map['deleted'] = Variable<bool>(deleted);
    map['country'] = Variable<String>(country);
    map['route_id'] = Variable<String>(routeId);
    map['title'] = Variable<String>(title);
    map['status'] = Variable<String>(status);
    map['trigger'] = Variable<String>(trigger);
    map['milestones'] = Variable<String>(milestones);
    map['notes'] = Variable<String>(notes);
    map['added'] = Variable<String>(added);
    return map;
  }

  CareerTracksCompanion toCompanion(bool nullToAbsent) {
    return CareerTracksCompanion(
      id: Value(id),
      hlc: Value(hlc),
      deleted: Value(deleted),
      country: Value(country),
      routeId: Value(routeId),
      title: Value(title),
      status: Value(status),
      trigger: Value(trigger),
      milestones: Value(milestones),
      notes: Value(notes),
      added: Value(added),
    );
  }

  factory RouteTrack.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RouteTrack(
      id: serializer.fromJson<String>(json['id']),
      hlc: serializer.fromJson<String>(json['hlc']),
      deleted: serializer.fromJson<bool>(json['deleted']),
      country: serializer.fromJson<String>(json['country']),
      routeId: serializer.fromJson<String>(json['routeId']),
      title: serializer.fromJson<String>(json['title']),
      status: serializer.fromJson<String>(json['status']),
      trigger: serializer.fromJson<String>(json['trigger']),
      milestones: serializer.fromJson<String>(json['milestones']),
      notes: serializer.fromJson<String>(json['notes']),
      added: serializer.fromJson<String>(json['added']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'hlc': serializer.toJson<String>(hlc),
      'deleted': serializer.toJson<bool>(deleted),
      'country': serializer.toJson<String>(country),
      'routeId': serializer.toJson<String>(routeId),
      'title': serializer.toJson<String>(title),
      'status': serializer.toJson<String>(status),
      'trigger': serializer.toJson<String>(trigger),
      'milestones': serializer.toJson<String>(milestones),
      'notes': serializer.toJson<String>(notes),
      'added': serializer.toJson<String>(added),
    };
  }

  RouteTrack copyWith({
    String? id,
    String? hlc,
    bool? deleted,
    String? country,
    String? routeId,
    String? title,
    String? status,
    String? trigger,
    String? milestones,
    String? notes,
    String? added,
  }) => RouteTrack(
    id: id ?? this.id,
    hlc: hlc ?? this.hlc,
    deleted: deleted ?? this.deleted,
    country: country ?? this.country,
    routeId: routeId ?? this.routeId,
    title: title ?? this.title,
    status: status ?? this.status,
    trigger: trigger ?? this.trigger,
    milestones: milestones ?? this.milestones,
    notes: notes ?? this.notes,
    added: added ?? this.added,
  );
  RouteTrack copyWithCompanion(CareerTracksCompanion data) {
    return RouteTrack(
      id: data.id.present ? data.id.value : this.id,
      hlc: data.hlc.present ? data.hlc.value : this.hlc,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      country: data.country.present ? data.country.value : this.country,
      routeId: data.routeId.present ? data.routeId.value : this.routeId,
      title: data.title.present ? data.title.value : this.title,
      status: data.status.present ? data.status.value : this.status,
      trigger: data.trigger.present ? data.trigger.value : this.trigger,
      milestones: data.milestones.present
          ? data.milestones.value
          : this.milestones,
      notes: data.notes.present ? data.notes.value : this.notes,
      added: data.added.present ? data.added.value : this.added,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RouteTrack(')
          ..write('id: $id, ')
          ..write('hlc: $hlc, ')
          ..write('deleted: $deleted, ')
          ..write('country: $country, ')
          ..write('routeId: $routeId, ')
          ..write('title: $title, ')
          ..write('status: $status, ')
          ..write('trigger: $trigger, ')
          ..write('milestones: $milestones, ')
          ..write('notes: $notes, ')
          ..write('added: $added')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    hlc,
    deleted,
    country,
    routeId,
    title,
    status,
    trigger,
    milestones,
    notes,
    added,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RouteTrack &&
          other.id == this.id &&
          other.hlc == this.hlc &&
          other.deleted == this.deleted &&
          other.country == this.country &&
          other.routeId == this.routeId &&
          other.title == this.title &&
          other.status == this.status &&
          other.trigger == this.trigger &&
          other.milestones == this.milestones &&
          other.notes == this.notes &&
          other.added == this.added);
}

class CareerTracksCompanion extends UpdateCompanion<RouteTrack> {
  final Value<String> id;
  final Value<String> hlc;
  final Value<bool> deleted;
  final Value<String> country;
  final Value<String> routeId;
  final Value<String> title;
  final Value<String> status;
  final Value<String> trigger;
  final Value<String> milestones;
  final Value<String> notes;
  final Value<String> added;
  final Value<int> rowid;
  const CareerTracksCompanion({
    this.id = const Value.absent(),
    this.hlc = const Value.absent(),
    this.deleted = const Value.absent(),
    this.country = const Value.absent(),
    this.routeId = const Value.absent(),
    this.title = const Value.absent(),
    this.status = const Value.absent(),
    this.trigger = const Value.absent(),
    this.milestones = const Value.absent(),
    this.notes = const Value.absent(),
    this.added = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CareerTracksCompanion.insert({
    required String id,
    this.hlc = const Value.absent(),
    this.deleted = const Value.absent(),
    required String country,
    this.routeId = const Value.absent(),
    required String title,
    this.status = const Value.absent(),
    this.trigger = const Value.absent(),
    this.milestones = const Value.absent(),
    this.notes = const Value.absent(),
    required String added,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       country = Value(country),
       title = Value(title),
       added = Value(added);
  static Insertable<RouteTrack> custom({
    Expression<String>? id,
    Expression<String>? hlc,
    Expression<bool>? deleted,
    Expression<String>? country,
    Expression<String>? routeId,
    Expression<String>? title,
    Expression<String>? status,
    Expression<String>? trigger,
    Expression<String>? milestones,
    Expression<String>? notes,
    Expression<String>? added,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (hlc != null) 'hlc': hlc,
      if (deleted != null) 'deleted': deleted,
      if (country != null) 'country': country,
      if (routeId != null) 'route_id': routeId,
      if (title != null) 'title': title,
      if (status != null) 'status': status,
      if (trigger != null) 'trigger': trigger,
      if (milestones != null) 'milestones': milestones,
      if (notes != null) 'notes': notes,
      if (added != null) 'added': added,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CareerTracksCompanion copyWith({
    Value<String>? id,
    Value<String>? hlc,
    Value<bool>? deleted,
    Value<String>? country,
    Value<String>? routeId,
    Value<String>? title,
    Value<String>? status,
    Value<String>? trigger,
    Value<String>? milestones,
    Value<String>? notes,
    Value<String>? added,
    Value<int>? rowid,
  }) {
    return CareerTracksCompanion(
      id: id ?? this.id,
      hlc: hlc ?? this.hlc,
      deleted: deleted ?? this.deleted,
      country: country ?? this.country,
      routeId: routeId ?? this.routeId,
      title: title ?? this.title,
      status: status ?? this.status,
      trigger: trigger ?? this.trigger,
      milestones: milestones ?? this.milestones,
      notes: notes ?? this.notes,
      added: added ?? this.added,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (hlc.present) {
      map['hlc'] = Variable<String>(hlc.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (country.present) {
      map['country'] = Variable<String>(country.value);
    }
    if (routeId.present) {
      map['route_id'] = Variable<String>(routeId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (trigger.present) {
      map['trigger'] = Variable<String>(trigger.value);
    }
    if (milestones.present) {
      map['milestones'] = Variable<String>(milestones.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (added.present) {
      map['added'] = Variable<String>(added.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CareerTracksCompanion(')
          ..write('id: $id, ')
          ..write('hlc: $hlc, ')
          ..write('deleted: $deleted, ')
          ..write('country: $country, ')
          ..write('routeId: $routeId, ')
          ..write('title: $title, ')
          ..write('status: $status, ')
          ..write('trigger: $trigger, ')
          ..write('milestones: $milestones, ')
          ..write('notes: $notes, ')
          ..write('added: $added, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CareerRoleProfilesTable extends CareerRoleProfiles
    with TableInfo<$CareerRoleProfilesTable, RoleProfileRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CareerRoleProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hlcMeta = const VerificationMeta('hlc');
  @override
  late final GeneratedColumn<String> hlc = GeneratedColumn<String>(
    'hlc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _deletedMeta = const VerificationMeta(
    'deleted',
  );
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _employerMeta = const VerificationMeta(
    'employer',
  );
  @override
  late final GeneratedColumn<String> employer = GeneratedColumn<String>(
    'employer',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _jobIdMeta = const VerificationMeta('jobId');
  @override
  late final GeneratedColumn<String> jobId = GeneratedColumn<String>(
    'job_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _frameworkMeta = const VerificationMeta(
    'framework',
  );
  @override
  late final GeneratedColumn<String> framework = GeneratedColumn<String>(
    'framework',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('private'),
  );
  static const VerificationMeta _criteriaMeta = const VerificationMeta(
    'criteria',
  );
  @override
  late final GeneratedColumn<String> criteria = GeneratedColumn<String>(
    'criteria',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('manual'),
  );
  static const VerificationMeta _addedMeta = const VerificationMeta('added');
  @override
  late final GeneratedColumn<String> added = GeneratedColumn<String>(
    'added',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedMeta = const VerificationMeta(
    'updated',
  );
  @override
  late final GeneratedColumn<String> updated = GeneratedColumn<String>(
    'updated',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    hlc,
    deleted,
    title,
    employer,
    jobId,
    framework,
    criteria,
    source,
    added,
    updated,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'career_role_profiles';
  @override
  VerificationContext validateIntegrity(
    Insertable<RoleProfileRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('hlc')) {
      context.handle(
        _hlcMeta,
        hlc.isAcceptableOrUnknown(data['hlc']!, _hlcMeta),
      );
    }
    if (data.containsKey('deleted')) {
      context.handle(
        _deletedMeta,
        deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('employer')) {
      context.handle(
        _employerMeta,
        employer.isAcceptableOrUnknown(data['employer']!, _employerMeta),
      );
    }
    if (data.containsKey('job_id')) {
      context.handle(
        _jobIdMeta,
        jobId.isAcceptableOrUnknown(data['job_id']!, _jobIdMeta),
      );
    }
    if (data.containsKey('framework')) {
      context.handle(
        _frameworkMeta,
        framework.isAcceptableOrUnknown(data['framework']!, _frameworkMeta),
      );
    }
    if (data.containsKey('criteria')) {
      context.handle(
        _criteriaMeta,
        criteria.isAcceptableOrUnknown(data['criteria']!, _criteriaMeta),
      );
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    if (data.containsKey('added')) {
      context.handle(
        _addedMeta,
        added.isAcceptableOrUnknown(data['added']!, _addedMeta),
      );
    } else if (isInserting) {
      context.missing(_addedMeta);
    }
    if (data.containsKey('updated')) {
      context.handle(
        _updatedMeta,
        updated.isAcceptableOrUnknown(data['updated']!, _updatedMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RoleProfileRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RoleProfileRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      hlc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hlc'],
      )!,
      deleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      employer: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}employer'],
      )!,
      jobId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}job_id'],
      ),
      framework: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}framework'],
      )!,
      criteria: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}criteria'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      added: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}added'],
      )!,
      updated: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated'],
      )!,
    );
  }

  @override
  $CareerRoleProfilesTable createAlias(String alias) {
    return $CareerRoleProfilesTable(attachedDatabase, alias);
  }
}

class RoleProfileRow extends DataClass implements Insertable<RoleProfileRow> {
  final String id;
  final String hlc;
  final bool deleted;
  final String title;
  final String employer;
  final String? jobId;

  /// A framework id (domain/interview_scoring.dart).
  final String framework;

  /// Criterion list as JSON.
  final String criteria;

  /// ai | manual
  final String source;
  final String added;
  final String updated;
  const RoleProfileRow({
    required this.id,
    required this.hlc,
    required this.deleted,
    required this.title,
    required this.employer,
    this.jobId,
    required this.framework,
    required this.criteria,
    required this.source,
    required this.added,
    required this.updated,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['hlc'] = Variable<String>(hlc);
    map['deleted'] = Variable<bool>(deleted);
    map['title'] = Variable<String>(title);
    map['employer'] = Variable<String>(employer);
    if (!nullToAbsent || jobId != null) {
      map['job_id'] = Variable<String>(jobId);
    }
    map['framework'] = Variable<String>(framework);
    map['criteria'] = Variable<String>(criteria);
    map['source'] = Variable<String>(source);
    map['added'] = Variable<String>(added);
    map['updated'] = Variable<String>(updated);
    return map;
  }

  CareerRoleProfilesCompanion toCompanion(bool nullToAbsent) {
    return CareerRoleProfilesCompanion(
      id: Value(id),
      hlc: Value(hlc),
      deleted: Value(deleted),
      title: Value(title),
      employer: Value(employer),
      jobId: jobId == null && nullToAbsent
          ? const Value.absent()
          : Value(jobId),
      framework: Value(framework),
      criteria: Value(criteria),
      source: Value(source),
      added: Value(added),
      updated: Value(updated),
    );
  }

  factory RoleProfileRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RoleProfileRow(
      id: serializer.fromJson<String>(json['id']),
      hlc: serializer.fromJson<String>(json['hlc']),
      deleted: serializer.fromJson<bool>(json['deleted']),
      title: serializer.fromJson<String>(json['title']),
      employer: serializer.fromJson<String>(json['employer']),
      jobId: serializer.fromJson<String?>(json['jobId']),
      framework: serializer.fromJson<String>(json['framework']),
      criteria: serializer.fromJson<String>(json['criteria']),
      source: serializer.fromJson<String>(json['source']),
      added: serializer.fromJson<String>(json['added']),
      updated: serializer.fromJson<String>(json['updated']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'hlc': serializer.toJson<String>(hlc),
      'deleted': serializer.toJson<bool>(deleted),
      'title': serializer.toJson<String>(title),
      'employer': serializer.toJson<String>(employer),
      'jobId': serializer.toJson<String?>(jobId),
      'framework': serializer.toJson<String>(framework),
      'criteria': serializer.toJson<String>(criteria),
      'source': serializer.toJson<String>(source),
      'added': serializer.toJson<String>(added),
      'updated': serializer.toJson<String>(updated),
    };
  }

  RoleProfileRow copyWith({
    String? id,
    String? hlc,
    bool? deleted,
    String? title,
    String? employer,
    Value<String?> jobId = const Value.absent(),
    String? framework,
    String? criteria,
    String? source,
    String? added,
    String? updated,
  }) => RoleProfileRow(
    id: id ?? this.id,
    hlc: hlc ?? this.hlc,
    deleted: deleted ?? this.deleted,
    title: title ?? this.title,
    employer: employer ?? this.employer,
    jobId: jobId.present ? jobId.value : this.jobId,
    framework: framework ?? this.framework,
    criteria: criteria ?? this.criteria,
    source: source ?? this.source,
    added: added ?? this.added,
    updated: updated ?? this.updated,
  );
  RoleProfileRow copyWithCompanion(CareerRoleProfilesCompanion data) {
    return RoleProfileRow(
      id: data.id.present ? data.id.value : this.id,
      hlc: data.hlc.present ? data.hlc.value : this.hlc,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      title: data.title.present ? data.title.value : this.title,
      employer: data.employer.present ? data.employer.value : this.employer,
      jobId: data.jobId.present ? data.jobId.value : this.jobId,
      framework: data.framework.present ? data.framework.value : this.framework,
      criteria: data.criteria.present ? data.criteria.value : this.criteria,
      source: data.source.present ? data.source.value : this.source,
      added: data.added.present ? data.added.value : this.added,
      updated: data.updated.present ? data.updated.value : this.updated,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RoleProfileRow(')
          ..write('id: $id, ')
          ..write('hlc: $hlc, ')
          ..write('deleted: $deleted, ')
          ..write('title: $title, ')
          ..write('employer: $employer, ')
          ..write('jobId: $jobId, ')
          ..write('framework: $framework, ')
          ..write('criteria: $criteria, ')
          ..write('source: $source, ')
          ..write('added: $added, ')
          ..write('updated: $updated')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    hlc,
    deleted,
    title,
    employer,
    jobId,
    framework,
    criteria,
    source,
    added,
    updated,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RoleProfileRow &&
          other.id == this.id &&
          other.hlc == this.hlc &&
          other.deleted == this.deleted &&
          other.title == this.title &&
          other.employer == this.employer &&
          other.jobId == this.jobId &&
          other.framework == this.framework &&
          other.criteria == this.criteria &&
          other.source == this.source &&
          other.added == this.added &&
          other.updated == this.updated);
}

class CareerRoleProfilesCompanion extends UpdateCompanion<RoleProfileRow> {
  final Value<String> id;
  final Value<String> hlc;
  final Value<bool> deleted;
  final Value<String> title;
  final Value<String> employer;
  final Value<String?> jobId;
  final Value<String> framework;
  final Value<String> criteria;
  final Value<String> source;
  final Value<String> added;
  final Value<String> updated;
  final Value<int> rowid;
  const CareerRoleProfilesCompanion({
    this.id = const Value.absent(),
    this.hlc = const Value.absent(),
    this.deleted = const Value.absent(),
    this.title = const Value.absent(),
    this.employer = const Value.absent(),
    this.jobId = const Value.absent(),
    this.framework = const Value.absent(),
    this.criteria = const Value.absent(),
    this.source = const Value.absent(),
    this.added = const Value.absent(),
    this.updated = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CareerRoleProfilesCompanion.insert({
    required String id,
    this.hlc = const Value.absent(),
    this.deleted = const Value.absent(),
    required String title,
    this.employer = const Value.absent(),
    this.jobId = const Value.absent(),
    this.framework = const Value.absent(),
    this.criteria = const Value.absent(),
    this.source = const Value.absent(),
    required String added,
    required String updated,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       added = Value(added),
       updated = Value(updated);
  static Insertable<RoleProfileRow> custom({
    Expression<String>? id,
    Expression<String>? hlc,
    Expression<bool>? deleted,
    Expression<String>? title,
    Expression<String>? employer,
    Expression<String>? jobId,
    Expression<String>? framework,
    Expression<String>? criteria,
    Expression<String>? source,
    Expression<String>? added,
    Expression<String>? updated,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (hlc != null) 'hlc': hlc,
      if (deleted != null) 'deleted': deleted,
      if (title != null) 'title': title,
      if (employer != null) 'employer': employer,
      if (jobId != null) 'job_id': jobId,
      if (framework != null) 'framework': framework,
      if (criteria != null) 'criteria': criteria,
      if (source != null) 'source': source,
      if (added != null) 'added': added,
      if (updated != null) 'updated': updated,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CareerRoleProfilesCompanion copyWith({
    Value<String>? id,
    Value<String>? hlc,
    Value<bool>? deleted,
    Value<String>? title,
    Value<String>? employer,
    Value<String?>? jobId,
    Value<String>? framework,
    Value<String>? criteria,
    Value<String>? source,
    Value<String>? added,
    Value<String>? updated,
    Value<int>? rowid,
  }) {
    return CareerRoleProfilesCompanion(
      id: id ?? this.id,
      hlc: hlc ?? this.hlc,
      deleted: deleted ?? this.deleted,
      title: title ?? this.title,
      employer: employer ?? this.employer,
      jobId: jobId ?? this.jobId,
      framework: framework ?? this.framework,
      criteria: criteria ?? this.criteria,
      source: source ?? this.source,
      added: added ?? this.added,
      updated: updated ?? this.updated,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (hlc.present) {
      map['hlc'] = Variable<String>(hlc.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (employer.present) {
      map['employer'] = Variable<String>(employer.value);
    }
    if (jobId.present) {
      map['job_id'] = Variable<String>(jobId.value);
    }
    if (framework.present) {
      map['framework'] = Variable<String>(framework.value);
    }
    if (criteria.present) {
      map['criteria'] = Variable<String>(criteria.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (added.present) {
      map['added'] = Variable<String>(added.value);
    }
    if (updated.present) {
      map['updated'] = Variable<String>(updated.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CareerRoleProfilesCompanion(')
          ..write('id: $id, ')
          ..write('hlc: $hlc, ')
          ..write('deleted: $deleted, ')
          ..write('title: $title, ')
          ..write('employer: $employer, ')
          ..write('jobId: $jobId, ')
          ..write('framework: $framework, ')
          ..write('criteria: $criteria, ')
          ..write('source: $source, ')
          ..write('added: $added, ')
          ..write('updated: $updated, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CareerProcessesTable extends CareerProcesses
    with TableInfo<$CareerProcessesTable, ProcessRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CareerProcessesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hlcMeta = const VerificationMeta('hlc');
  @override
  late final GeneratedColumn<String> hlc = GeneratedColumn<String>(
    'hlc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _deletedMeta = const VerificationMeta(
    'deleted',
  );
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
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
  static const VerificationMeta _templateMeta = const VerificationMeta(
    'template',
  );
  @override
  late final GeneratedColumn<String> template = GeneratedColumn<String>(
    'template',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _profileIdMeta = const VerificationMeta(
    'profileId',
  );
  @override
  late final GeneratedColumn<String> profileId = GeneratedColumn<String>(
    'profile_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _processMeta = const VerificationMeta(
    'process',
  );
  @override
  late final GeneratedColumn<String> process = GeneratedColumn<String>(
    'process',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _progressMeta = const VerificationMeta(
    'progress',
  );
  @override
  late final GeneratedColumn<String> progress = GeneratedColumn<String>(
    'progress',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _startedMeta = const VerificationMeta(
    'started',
  );
  @override
  late final GeneratedColumn<String> started = GeneratedColumn<String>(
    'started',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedMeta = const VerificationMeta(
    'updated',
  );
  @override
  late final GeneratedColumn<String> updated = GeneratedColumn<String>(
    'updated',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    hlc,
    deleted,
    name,
    template,
    profileId,
    process,
    progress,
    started,
    updated,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'career_processes';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProcessRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('hlc')) {
      context.handle(
        _hlcMeta,
        hlc.isAcceptableOrUnknown(data['hlc']!, _hlcMeta),
      );
    }
    if (data.containsKey('deleted')) {
      context.handle(
        _deletedMeta,
        deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('template')) {
      context.handle(
        _templateMeta,
        template.isAcceptableOrUnknown(data['template']!, _templateMeta),
      );
    }
    if (data.containsKey('profile_id')) {
      context.handle(
        _profileIdMeta,
        profileId.isAcceptableOrUnknown(data['profile_id']!, _profileIdMeta),
      );
    }
    if (data.containsKey('process')) {
      context.handle(
        _processMeta,
        process.isAcceptableOrUnknown(data['process']!, _processMeta),
      );
    } else if (isInserting) {
      context.missing(_processMeta);
    }
    if (data.containsKey('progress')) {
      context.handle(
        _progressMeta,
        progress.isAcceptableOrUnknown(data['progress']!, _progressMeta),
      );
    }
    if (data.containsKey('started')) {
      context.handle(
        _startedMeta,
        started.isAcceptableOrUnknown(data['started']!, _startedMeta),
      );
    } else if (isInserting) {
      context.missing(_startedMeta);
    }
    if (data.containsKey('updated')) {
      context.handle(
        _updatedMeta,
        updated.isAcceptableOrUnknown(data['updated']!, _updatedMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProcessRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProcessRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      hlc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hlc'],
      )!,
      deleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      template: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}template'],
      )!,
      profileId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}profile_id'],
      ),
      process: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}process'],
      )!,
      progress: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}progress'],
      )!,
      started: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}started'],
      )!,
      updated: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated'],
      )!,
    );
  }

  @override
  $CareerProcessesTable createAlias(String alias) {
    return $CareerProcessesTable(attachedDatabase, alias);
  }
}

class ProcessRow extends DataClass implements Insertable<ProcessRow> {
  final String id;
  final String hlc;
  final bool deleted;
  final String name;

  /// The template it started from.
  final String template;
  final String? profileId;

  /// InterviewProcess as JSON.
  final String process;

  /// ProcessProgress as JSON: each stage's round, what it covered and what
  /// it carries forward. Text only.
  final String progress;
  final String started;
  final String updated;
  const ProcessRow({
    required this.id,
    required this.hlc,
    required this.deleted,
    required this.name,
    required this.template,
    this.profileId,
    required this.process,
    required this.progress,
    required this.started,
    required this.updated,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['hlc'] = Variable<String>(hlc);
    map['deleted'] = Variable<bool>(deleted);
    map['name'] = Variable<String>(name);
    map['template'] = Variable<String>(template);
    if (!nullToAbsent || profileId != null) {
      map['profile_id'] = Variable<String>(profileId);
    }
    map['process'] = Variable<String>(process);
    map['progress'] = Variable<String>(progress);
    map['started'] = Variable<String>(started);
    map['updated'] = Variable<String>(updated);
    return map;
  }

  CareerProcessesCompanion toCompanion(bool nullToAbsent) {
    return CareerProcessesCompanion(
      id: Value(id),
      hlc: Value(hlc),
      deleted: Value(deleted),
      name: Value(name),
      template: Value(template),
      profileId: profileId == null && nullToAbsent
          ? const Value.absent()
          : Value(profileId),
      process: Value(process),
      progress: Value(progress),
      started: Value(started),
      updated: Value(updated),
    );
  }

  factory ProcessRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProcessRow(
      id: serializer.fromJson<String>(json['id']),
      hlc: serializer.fromJson<String>(json['hlc']),
      deleted: serializer.fromJson<bool>(json['deleted']),
      name: serializer.fromJson<String>(json['name']),
      template: serializer.fromJson<String>(json['template']),
      profileId: serializer.fromJson<String?>(json['profileId']),
      process: serializer.fromJson<String>(json['process']),
      progress: serializer.fromJson<String>(json['progress']),
      started: serializer.fromJson<String>(json['started']),
      updated: serializer.fromJson<String>(json['updated']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'hlc': serializer.toJson<String>(hlc),
      'deleted': serializer.toJson<bool>(deleted),
      'name': serializer.toJson<String>(name),
      'template': serializer.toJson<String>(template),
      'profileId': serializer.toJson<String?>(profileId),
      'process': serializer.toJson<String>(process),
      'progress': serializer.toJson<String>(progress),
      'started': serializer.toJson<String>(started),
      'updated': serializer.toJson<String>(updated),
    };
  }

  ProcessRow copyWith({
    String? id,
    String? hlc,
    bool? deleted,
    String? name,
    String? template,
    Value<String?> profileId = const Value.absent(),
    String? process,
    String? progress,
    String? started,
    String? updated,
  }) => ProcessRow(
    id: id ?? this.id,
    hlc: hlc ?? this.hlc,
    deleted: deleted ?? this.deleted,
    name: name ?? this.name,
    template: template ?? this.template,
    profileId: profileId.present ? profileId.value : this.profileId,
    process: process ?? this.process,
    progress: progress ?? this.progress,
    started: started ?? this.started,
    updated: updated ?? this.updated,
  );
  ProcessRow copyWithCompanion(CareerProcessesCompanion data) {
    return ProcessRow(
      id: data.id.present ? data.id.value : this.id,
      hlc: data.hlc.present ? data.hlc.value : this.hlc,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      name: data.name.present ? data.name.value : this.name,
      template: data.template.present ? data.template.value : this.template,
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      process: data.process.present ? data.process.value : this.process,
      progress: data.progress.present ? data.progress.value : this.progress,
      started: data.started.present ? data.started.value : this.started,
      updated: data.updated.present ? data.updated.value : this.updated,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProcessRow(')
          ..write('id: $id, ')
          ..write('hlc: $hlc, ')
          ..write('deleted: $deleted, ')
          ..write('name: $name, ')
          ..write('template: $template, ')
          ..write('profileId: $profileId, ')
          ..write('process: $process, ')
          ..write('progress: $progress, ')
          ..write('started: $started, ')
          ..write('updated: $updated')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    hlc,
    deleted,
    name,
    template,
    profileId,
    process,
    progress,
    started,
    updated,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProcessRow &&
          other.id == this.id &&
          other.hlc == this.hlc &&
          other.deleted == this.deleted &&
          other.name == this.name &&
          other.template == this.template &&
          other.profileId == this.profileId &&
          other.process == this.process &&
          other.progress == this.progress &&
          other.started == this.started &&
          other.updated == this.updated);
}

class CareerProcessesCompanion extends UpdateCompanion<ProcessRow> {
  final Value<String> id;
  final Value<String> hlc;
  final Value<bool> deleted;
  final Value<String> name;
  final Value<String> template;
  final Value<String?> profileId;
  final Value<String> process;
  final Value<String> progress;
  final Value<String> started;
  final Value<String> updated;
  final Value<int> rowid;
  const CareerProcessesCompanion({
    this.id = const Value.absent(),
    this.hlc = const Value.absent(),
    this.deleted = const Value.absent(),
    this.name = const Value.absent(),
    this.template = const Value.absent(),
    this.profileId = const Value.absent(),
    this.process = const Value.absent(),
    this.progress = const Value.absent(),
    this.started = const Value.absent(),
    this.updated = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CareerProcessesCompanion.insert({
    required String id,
    this.hlc = const Value.absent(),
    this.deleted = const Value.absent(),
    required String name,
    this.template = const Value.absent(),
    this.profileId = const Value.absent(),
    required String process,
    this.progress = const Value.absent(),
    required String started,
    required String updated,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       process = Value(process),
       started = Value(started),
       updated = Value(updated);
  static Insertable<ProcessRow> custom({
    Expression<String>? id,
    Expression<String>? hlc,
    Expression<bool>? deleted,
    Expression<String>? name,
    Expression<String>? template,
    Expression<String>? profileId,
    Expression<String>? process,
    Expression<String>? progress,
    Expression<String>? started,
    Expression<String>? updated,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (hlc != null) 'hlc': hlc,
      if (deleted != null) 'deleted': deleted,
      if (name != null) 'name': name,
      if (template != null) 'template': template,
      if (profileId != null) 'profile_id': profileId,
      if (process != null) 'process': process,
      if (progress != null) 'progress': progress,
      if (started != null) 'started': started,
      if (updated != null) 'updated': updated,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CareerProcessesCompanion copyWith({
    Value<String>? id,
    Value<String>? hlc,
    Value<bool>? deleted,
    Value<String>? name,
    Value<String>? template,
    Value<String?>? profileId,
    Value<String>? process,
    Value<String>? progress,
    Value<String>? started,
    Value<String>? updated,
    Value<int>? rowid,
  }) {
    return CareerProcessesCompanion(
      id: id ?? this.id,
      hlc: hlc ?? this.hlc,
      deleted: deleted ?? this.deleted,
      name: name ?? this.name,
      template: template ?? this.template,
      profileId: profileId ?? this.profileId,
      process: process ?? this.process,
      progress: progress ?? this.progress,
      started: started ?? this.started,
      updated: updated ?? this.updated,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (hlc.present) {
      map['hlc'] = Variable<String>(hlc.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (template.present) {
      map['template'] = Variable<String>(template.value);
    }
    if (profileId.present) {
      map['profile_id'] = Variable<String>(profileId.value);
    }
    if (process.present) {
      map['process'] = Variable<String>(process.value);
    }
    if (progress.present) {
      map['progress'] = Variable<String>(progress.value);
    }
    if (started.present) {
      map['started'] = Variable<String>(started.value);
    }
    if (updated.present) {
      map['updated'] = Variable<String>(updated.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CareerProcessesCompanion(')
          ..write('id: $id, ')
          ..write('hlc: $hlc, ')
          ..write('deleted: $deleted, ')
          ..write('name: $name, ')
          ..write('template: $template, ')
          ..write('profileId: $profileId, ')
          ..write('process: $process, ')
          ..write('progress: $progress, ')
          ..write('started: $started, ')
          ..write('updated: $updated, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BridgeStudyPlansTable extends BridgeStudyPlans
    with TableInfo<$BridgeStudyPlansTable, StudyPlan> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BridgeStudyPlansTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hlcMeta = const VerificationMeta('hlc');
  @override
  late final GeneratedColumn<String> hlc = GeneratedColumn<String>(
    'hlc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _deletedMeta = const VerificationMeta(
    'deleted',
  );
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _planMeta = const VerificationMeta('plan');
  @override
  late final GeneratedColumn<String> plan = GeneratedColumn<String>(
    'plan',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedMeta = const VerificationMeta(
    'updated',
  );
  @override
  late final GeneratedColumn<String> updated = GeneratedColumn<String>(
    'updated',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    hlc,
    deleted,
    source,
    plan,
    updated,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bridge_study_plans';
  @override
  VerificationContext validateIntegrity(
    Insertable<StudyPlan> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('hlc')) {
      context.handle(
        _hlcMeta,
        hlc.isAcceptableOrUnknown(data['hlc']!, _hlcMeta),
      );
    }
    if (data.containsKey('deleted')) {
      context.handle(
        _deletedMeta,
        deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta),
      );
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('plan')) {
      context.handle(
        _planMeta,
        plan.isAcceptableOrUnknown(data['plan']!, _planMeta),
      );
    } else if (isInserting) {
      context.missing(_planMeta);
    }
    if (data.containsKey('updated')) {
      context.handle(
        _updatedMeta,
        updated.isAcceptableOrUnknown(data['updated']!, _updatedMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StudyPlan map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StudyPlan(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      hlc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hlc'],
      )!,
      deleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      plan: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}plan'],
      )!,
      updated: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated'],
      )!,
    );
  }

  @override
  $BridgeStudyPlansTable createAlias(String alias) {
    return $BridgeStudyPlansTable(attachedDatabase, alias);
  }
}

class StudyPlan extends DataClass implements Insertable<StudyPlan> {
  final String id;
  final String hlc;
  final bool deleted;

  /// The app that wrote it, as its identity id (`udyoga`).
  final String source;

  /// The plan, as "vidya-curriculum" JSON (version 1).
  final String plan;

  /// When it was last sent (UTC, ISO 8601). Tells the reader it changed.
  final String updated;
  const StudyPlan({
    required this.id,
    required this.hlc,
    required this.deleted,
    required this.source,
    required this.plan,
    required this.updated,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['hlc'] = Variable<String>(hlc);
    map['deleted'] = Variable<bool>(deleted);
    map['source'] = Variable<String>(source);
    map['plan'] = Variable<String>(plan);
    map['updated'] = Variable<String>(updated);
    return map;
  }

  BridgeStudyPlansCompanion toCompanion(bool nullToAbsent) {
    return BridgeStudyPlansCompanion(
      id: Value(id),
      hlc: Value(hlc),
      deleted: Value(deleted),
      source: Value(source),
      plan: Value(plan),
      updated: Value(updated),
    );
  }

  factory StudyPlan.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StudyPlan(
      id: serializer.fromJson<String>(json['id']),
      hlc: serializer.fromJson<String>(json['hlc']),
      deleted: serializer.fromJson<bool>(json['deleted']),
      source: serializer.fromJson<String>(json['source']),
      plan: serializer.fromJson<String>(json['plan']),
      updated: serializer.fromJson<String>(json['updated']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'hlc': serializer.toJson<String>(hlc),
      'deleted': serializer.toJson<bool>(deleted),
      'source': serializer.toJson<String>(source),
      'plan': serializer.toJson<String>(plan),
      'updated': serializer.toJson<String>(updated),
    };
  }

  StudyPlan copyWith({
    String? id,
    String? hlc,
    bool? deleted,
    String? source,
    String? plan,
    String? updated,
  }) => StudyPlan(
    id: id ?? this.id,
    hlc: hlc ?? this.hlc,
    deleted: deleted ?? this.deleted,
    source: source ?? this.source,
    plan: plan ?? this.plan,
    updated: updated ?? this.updated,
  );
  StudyPlan copyWithCompanion(BridgeStudyPlansCompanion data) {
    return StudyPlan(
      id: data.id.present ? data.id.value : this.id,
      hlc: data.hlc.present ? data.hlc.value : this.hlc,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      source: data.source.present ? data.source.value : this.source,
      plan: data.plan.present ? data.plan.value : this.plan,
      updated: data.updated.present ? data.updated.value : this.updated,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StudyPlan(')
          ..write('id: $id, ')
          ..write('hlc: $hlc, ')
          ..write('deleted: $deleted, ')
          ..write('source: $source, ')
          ..write('plan: $plan, ')
          ..write('updated: $updated')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, hlc, deleted, source, plan, updated);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StudyPlan &&
          other.id == this.id &&
          other.hlc == this.hlc &&
          other.deleted == this.deleted &&
          other.source == this.source &&
          other.plan == this.plan &&
          other.updated == this.updated);
}

class BridgeStudyPlansCompanion extends UpdateCompanion<StudyPlan> {
  final Value<String> id;
  final Value<String> hlc;
  final Value<bool> deleted;
  final Value<String> source;
  final Value<String> plan;
  final Value<String> updated;
  final Value<int> rowid;
  const BridgeStudyPlansCompanion({
    this.id = const Value.absent(),
    this.hlc = const Value.absent(),
    this.deleted = const Value.absent(),
    this.source = const Value.absent(),
    this.plan = const Value.absent(),
    this.updated = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BridgeStudyPlansCompanion.insert({
    required String id,
    this.hlc = const Value.absent(),
    this.deleted = const Value.absent(),
    required String source,
    required String plan,
    required String updated,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       source = Value(source),
       plan = Value(plan),
       updated = Value(updated);
  static Insertable<StudyPlan> custom({
    Expression<String>? id,
    Expression<String>? hlc,
    Expression<bool>? deleted,
    Expression<String>? source,
    Expression<String>? plan,
    Expression<String>? updated,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (hlc != null) 'hlc': hlc,
      if (deleted != null) 'deleted': deleted,
      if (source != null) 'source': source,
      if (plan != null) 'plan': plan,
      if (updated != null) 'updated': updated,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BridgeStudyPlansCompanion copyWith({
    Value<String>? id,
    Value<String>? hlc,
    Value<bool>? deleted,
    Value<String>? source,
    Value<String>? plan,
    Value<String>? updated,
    Value<int>? rowid,
  }) {
    return BridgeStudyPlansCompanion(
      id: id ?? this.id,
      hlc: hlc ?? this.hlc,
      deleted: deleted ?? this.deleted,
      source: source ?? this.source,
      plan: plan ?? this.plan,
      updated: updated ?? this.updated,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (hlc.present) {
      map['hlc'] = Variable<String>(hlc.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (plan.present) {
      map['plan'] = Variable<String>(plan.value);
    }
    if (updated.present) {
      map['updated'] = Variable<String>(updated.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BridgeStudyPlansCompanion(')
          ..write('id: $id, ')
          ..write('hlc: $hlc, ')
          ..write('deleted: $deleted, ')
          ..write('source: $source, ')
          ..write('plan: $plan, ')
          ..write('updated: $updated, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BridgeStudyProgressTable extends BridgeStudyProgress
    with TableInfo<$BridgeStudyProgressTable, StudyProgressRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BridgeStudyProgressTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hlcMeta = const VerificationMeta('hlc');
  @override
  late final GeneratedColumn<String> hlc = GeneratedColumn<String>(
    'hlc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _deletedMeta = const VerificationMeta(
    'deleted',
  );
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _planUpdatedMeta = const VerificationMeta(
    'planUpdated',
  );
  @override
  late final GeneratedColumn<String> planUpdated = GeneratedColumn<String>(
    'plan_updated',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _progressMeta = const VerificationMeta(
    'progress',
  );
  @override
  late final GeneratedColumn<String> progress = GeneratedColumn<String>(
    'progress',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _updatedMeta = const VerificationMeta(
    'updated',
  );
  @override
  late final GeneratedColumn<String> updated = GeneratedColumn<String>(
    'updated',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    hlc,
    deleted,
    planUpdated,
    progress,
    updated,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bridge_study_progress';
  @override
  VerificationContext validateIntegrity(
    Insertable<StudyProgressRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('hlc')) {
      context.handle(
        _hlcMeta,
        hlc.isAcceptableOrUnknown(data['hlc']!, _hlcMeta),
      );
    }
    if (data.containsKey('deleted')) {
      context.handle(
        _deletedMeta,
        deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta),
      );
    }
    if (data.containsKey('plan_updated')) {
      context.handle(
        _planUpdatedMeta,
        planUpdated.isAcceptableOrUnknown(
          data['plan_updated']!,
          _planUpdatedMeta,
        ),
      );
    }
    if (data.containsKey('progress')) {
      context.handle(
        _progressMeta,
        progress.isAcceptableOrUnknown(data['progress']!, _progressMeta),
      );
    }
    if (data.containsKey('updated')) {
      context.handle(
        _updatedMeta,
        updated.isAcceptableOrUnknown(data['updated']!, _updatedMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StudyProgressRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StudyProgressRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      hlc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hlc'],
      )!,
      deleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted'],
      )!,
      planUpdated: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}plan_updated'],
      )!,
      progress: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}progress'],
      )!,
      updated: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated'],
      )!,
    );
  }

  @override
  $BridgeStudyProgressTable createAlias(String alias) {
    return $BridgeStudyProgressTable(attachedDatabase, alias);
  }
}

class StudyProgressRow extends DataClass
    implements Insertable<StudyProgressRow> {
  final String id;
  final String hlc;
  final bool deleted;

  /// The `updated` of the plan version added to the learning app; empty
  /// until it is added.
  final String planUpdated;

  /// [StudyProgress] as JSON.
  final String progress;

  /// When the progress last changed (UTC, ISO 8601).
  final String updated;
  const StudyProgressRow({
    required this.id,
    required this.hlc,
    required this.deleted,
    required this.planUpdated,
    required this.progress,
    required this.updated,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['hlc'] = Variable<String>(hlc);
    map['deleted'] = Variable<bool>(deleted);
    map['plan_updated'] = Variable<String>(planUpdated);
    map['progress'] = Variable<String>(progress);
    map['updated'] = Variable<String>(updated);
    return map;
  }

  BridgeStudyProgressCompanion toCompanion(bool nullToAbsent) {
    return BridgeStudyProgressCompanion(
      id: Value(id),
      hlc: Value(hlc),
      deleted: Value(deleted),
      planUpdated: Value(planUpdated),
      progress: Value(progress),
      updated: Value(updated),
    );
  }

  factory StudyProgressRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StudyProgressRow(
      id: serializer.fromJson<String>(json['id']),
      hlc: serializer.fromJson<String>(json['hlc']),
      deleted: serializer.fromJson<bool>(json['deleted']),
      planUpdated: serializer.fromJson<String>(json['planUpdated']),
      progress: serializer.fromJson<String>(json['progress']),
      updated: serializer.fromJson<String>(json['updated']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'hlc': serializer.toJson<String>(hlc),
      'deleted': serializer.toJson<bool>(deleted),
      'planUpdated': serializer.toJson<String>(planUpdated),
      'progress': serializer.toJson<String>(progress),
      'updated': serializer.toJson<String>(updated),
    };
  }

  StudyProgressRow copyWith({
    String? id,
    String? hlc,
    bool? deleted,
    String? planUpdated,
    String? progress,
    String? updated,
  }) => StudyProgressRow(
    id: id ?? this.id,
    hlc: hlc ?? this.hlc,
    deleted: deleted ?? this.deleted,
    planUpdated: planUpdated ?? this.planUpdated,
    progress: progress ?? this.progress,
    updated: updated ?? this.updated,
  );
  StudyProgressRow copyWithCompanion(BridgeStudyProgressCompanion data) {
    return StudyProgressRow(
      id: data.id.present ? data.id.value : this.id,
      hlc: data.hlc.present ? data.hlc.value : this.hlc,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      planUpdated: data.planUpdated.present
          ? data.planUpdated.value
          : this.planUpdated,
      progress: data.progress.present ? data.progress.value : this.progress,
      updated: data.updated.present ? data.updated.value : this.updated,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StudyProgressRow(')
          ..write('id: $id, ')
          ..write('hlc: $hlc, ')
          ..write('deleted: $deleted, ')
          ..write('planUpdated: $planUpdated, ')
          ..write('progress: $progress, ')
          ..write('updated: $updated')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, hlc, deleted, planUpdated, progress, updated);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StudyProgressRow &&
          other.id == this.id &&
          other.hlc == this.hlc &&
          other.deleted == this.deleted &&
          other.planUpdated == this.planUpdated &&
          other.progress == this.progress &&
          other.updated == this.updated);
}

class BridgeStudyProgressCompanion extends UpdateCompanion<StudyProgressRow> {
  final Value<String> id;
  final Value<String> hlc;
  final Value<bool> deleted;
  final Value<String> planUpdated;
  final Value<String> progress;
  final Value<String> updated;
  final Value<int> rowid;
  const BridgeStudyProgressCompanion({
    this.id = const Value.absent(),
    this.hlc = const Value.absent(),
    this.deleted = const Value.absent(),
    this.planUpdated = const Value.absent(),
    this.progress = const Value.absent(),
    this.updated = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BridgeStudyProgressCompanion.insert({
    required String id,
    this.hlc = const Value.absent(),
    this.deleted = const Value.absent(),
    this.planUpdated = const Value.absent(),
    this.progress = const Value.absent(),
    required String updated,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       updated = Value(updated);
  static Insertable<StudyProgressRow> custom({
    Expression<String>? id,
    Expression<String>? hlc,
    Expression<bool>? deleted,
    Expression<String>? planUpdated,
    Expression<String>? progress,
    Expression<String>? updated,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (hlc != null) 'hlc': hlc,
      if (deleted != null) 'deleted': deleted,
      if (planUpdated != null) 'plan_updated': planUpdated,
      if (progress != null) 'progress': progress,
      if (updated != null) 'updated': updated,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BridgeStudyProgressCompanion copyWith({
    Value<String>? id,
    Value<String>? hlc,
    Value<bool>? deleted,
    Value<String>? planUpdated,
    Value<String>? progress,
    Value<String>? updated,
    Value<int>? rowid,
  }) {
    return BridgeStudyProgressCompanion(
      id: id ?? this.id,
      hlc: hlc ?? this.hlc,
      deleted: deleted ?? this.deleted,
      planUpdated: planUpdated ?? this.planUpdated,
      progress: progress ?? this.progress,
      updated: updated ?? this.updated,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (hlc.present) {
      map['hlc'] = Variable<String>(hlc.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (planUpdated.present) {
      map['plan_updated'] = Variable<String>(planUpdated.value);
    }
    if (progress.present) {
      map['progress'] = Variable<String>(progress.value);
    }
    if (updated.present) {
      map['updated'] = Variable<String>(updated.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BridgeStudyProgressCompanion(')
          ..write('id: $id, ')
          ..write('hlc: $hlc, ')
          ..write('deleted: $deleted, ')
          ..write('planUpdated: $planUpdated, ')
          ..write('progress: $progress, ')
          ..write('updated: $updated, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CareerFileDocsTable extends CareerFileDocs
    with TableInfo<$CareerFileDocsTable, CareerFileDoc> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CareerFileDocsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hlcMeta = const VerificationMeta('hlc');
  @override
  late final GeneratedColumn<String> hlc = GeneratedColumn<String>(
    'hlc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _deletedMeta = const VerificationMeta(
    'deleted',
  );
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _pathMeta = const VerificationMeta('path');
  @override
  late final GeneratedColumn<String> path = GeneratedColumn<String>(
    'path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sha256Meta = const VerificationMeta('sha256');
  @override
  late final GeneratedColumn<String> sha256 = GeneratedColumn<String>(
    'sha256',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _updatedMeta = const VerificationMeta(
    'updated',
  );
  @override
  late final GeneratedColumn<String> updated = GeneratedColumn<String>(
    'updated',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deviceMeta = const VerificationMeta('device');
  @override
  late final GeneratedColumn<String> device = GeneratedColumn<String>(
    'device',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    hlc,
    deleted,
    path,
    kind,
    sha256,
    content,
    updated,
    device,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'career_file_docs';
  @override
  VerificationContext validateIntegrity(
    Insertable<CareerFileDoc> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('hlc')) {
      context.handle(
        _hlcMeta,
        hlc.isAcceptableOrUnknown(data['hlc']!, _hlcMeta),
      );
    }
    if (data.containsKey('deleted')) {
      context.handle(
        _deletedMeta,
        deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta),
      );
    }
    if (data.containsKey('path')) {
      context.handle(
        _pathMeta,
        path.isAcceptableOrUnknown(data['path']!, _pathMeta),
      );
    } else if (isInserting) {
      context.missing(_pathMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('sha256')) {
      context.handle(
        _sha256Meta,
        sha256.isAcceptableOrUnknown(data['sha256']!, _sha256Meta),
      );
    } else if (isInserting) {
      context.missing(_sha256Meta);
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    }
    if (data.containsKey('updated')) {
      context.handle(
        _updatedMeta,
        updated.isAcceptableOrUnknown(data['updated']!, _updatedMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedMeta);
    }
    if (data.containsKey('device')) {
      context.handle(
        _deviceMeta,
        device.isAcceptableOrUnknown(data['device']!, _deviceMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CareerFileDoc map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CareerFileDoc(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      hlc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hlc'],
      )!,
      deleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted'],
      )!,
      path: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}path'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      sha256: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sha256'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      updated: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated'],
      )!,
      device: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device'],
      )!,
    );
  }

  @override
  $CareerFileDocsTable createAlias(String alias) {
    return $CareerFileDocsTable(attachedDatabase, alias);
  }
}

class CareerFileDoc extends DataClass implements Insertable<CareerFileDoc> {
  final String id;
  final String hlc;
  final bool deleted;

  /// Relative to the career folder, with forward slashes:
  /// `settings/udyoga.json`, `settings/vidya-….json`, `recipes/….json`.
  final String path;

  /// settings | vidya-plan | recipe
  final String kind;

  /// SHA-256 of [content] as UTF-8, hex.
  final String sha256;

  /// The file's text; '' once removed from the folder (the row is then
  /// tombstoned).
  final String content;

  /// When this version was read (UTC, ISO 8601).
  final String updated;

  /// The device that read it: its name, for "from device …".
  final String device;
  const CareerFileDoc({
    required this.id,
    required this.hlc,
    required this.deleted,
    required this.path,
    required this.kind,
    required this.sha256,
    required this.content,
    required this.updated,
    required this.device,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['hlc'] = Variable<String>(hlc);
    map['deleted'] = Variable<bool>(deleted);
    map['path'] = Variable<String>(path);
    map['kind'] = Variable<String>(kind);
    map['sha256'] = Variable<String>(sha256);
    map['content'] = Variable<String>(content);
    map['updated'] = Variable<String>(updated);
    map['device'] = Variable<String>(device);
    return map;
  }

  CareerFileDocsCompanion toCompanion(bool nullToAbsent) {
    return CareerFileDocsCompanion(
      id: Value(id),
      hlc: Value(hlc),
      deleted: Value(deleted),
      path: Value(path),
      kind: Value(kind),
      sha256: Value(sha256),
      content: Value(content),
      updated: Value(updated),
      device: Value(device),
    );
  }

  factory CareerFileDoc.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CareerFileDoc(
      id: serializer.fromJson<String>(json['id']),
      hlc: serializer.fromJson<String>(json['hlc']),
      deleted: serializer.fromJson<bool>(json['deleted']),
      path: serializer.fromJson<String>(json['path']),
      kind: serializer.fromJson<String>(json['kind']),
      sha256: serializer.fromJson<String>(json['sha256']),
      content: serializer.fromJson<String>(json['content']),
      updated: serializer.fromJson<String>(json['updated']),
      device: serializer.fromJson<String>(json['device']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'hlc': serializer.toJson<String>(hlc),
      'deleted': serializer.toJson<bool>(deleted),
      'path': serializer.toJson<String>(path),
      'kind': serializer.toJson<String>(kind),
      'sha256': serializer.toJson<String>(sha256),
      'content': serializer.toJson<String>(content),
      'updated': serializer.toJson<String>(updated),
      'device': serializer.toJson<String>(device),
    };
  }

  CareerFileDoc copyWith({
    String? id,
    String? hlc,
    bool? deleted,
    String? path,
    String? kind,
    String? sha256,
    String? content,
    String? updated,
    String? device,
  }) => CareerFileDoc(
    id: id ?? this.id,
    hlc: hlc ?? this.hlc,
    deleted: deleted ?? this.deleted,
    path: path ?? this.path,
    kind: kind ?? this.kind,
    sha256: sha256 ?? this.sha256,
    content: content ?? this.content,
    updated: updated ?? this.updated,
    device: device ?? this.device,
  );
  CareerFileDoc copyWithCompanion(CareerFileDocsCompanion data) {
    return CareerFileDoc(
      id: data.id.present ? data.id.value : this.id,
      hlc: data.hlc.present ? data.hlc.value : this.hlc,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      path: data.path.present ? data.path.value : this.path,
      kind: data.kind.present ? data.kind.value : this.kind,
      sha256: data.sha256.present ? data.sha256.value : this.sha256,
      content: data.content.present ? data.content.value : this.content,
      updated: data.updated.present ? data.updated.value : this.updated,
      device: data.device.present ? data.device.value : this.device,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CareerFileDoc(')
          ..write('id: $id, ')
          ..write('hlc: $hlc, ')
          ..write('deleted: $deleted, ')
          ..write('path: $path, ')
          ..write('kind: $kind, ')
          ..write('sha256: $sha256, ')
          ..write('content: $content, ')
          ..write('updated: $updated, ')
          ..write('device: $device')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    hlc,
    deleted,
    path,
    kind,
    sha256,
    content,
    updated,
    device,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CareerFileDoc &&
          other.id == this.id &&
          other.hlc == this.hlc &&
          other.deleted == this.deleted &&
          other.path == this.path &&
          other.kind == this.kind &&
          other.sha256 == this.sha256 &&
          other.content == this.content &&
          other.updated == this.updated &&
          other.device == this.device);
}

class CareerFileDocsCompanion extends UpdateCompanion<CareerFileDoc> {
  final Value<String> id;
  final Value<String> hlc;
  final Value<bool> deleted;
  final Value<String> path;
  final Value<String> kind;
  final Value<String> sha256;
  final Value<String> content;
  final Value<String> updated;
  final Value<String> device;
  final Value<int> rowid;
  const CareerFileDocsCompanion({
    this.id = const Value.absent(),
    this.hlc = const Value.absent(),
    this.deleted = const Value.absent(),
    this.path = const Value.absent(),
    this.kind = const Value.absent(),
    this.sha256 = const Value.absent(),
    this.content = const Value.absent(),
    this.updated = const Value.absent(),
    this.device = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CareerFileDocsCompanion.insert({
    required String id,
    this.hlc = const Value.absent(),
    this.deleted = const Value.absent(),
    required String path,
    required String kind,
    required String sha256,
    this.content = const Value.absent(),
    required String updated,
    this.device = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       path = Value(path),
       kind = Value(kind),
       sha256 = Value(sha256),
       updated = Value(updated);
  static Insertable<CareerFileDoc> custom({
    Expression<String>? id,
    Expression<String>? hlc,
    Expression<bool>? deleted,
    Expression<String>? path,
    Expression<String>? kind,
    Expression<String>? sha256,
    Expression<String>? content,
    Expression<String>? updated,
    Expression<String>? device,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (hlc != null) 'hlc': hlc,
      if (deleted != null) 'deleted': deleted,
      if (path != null) 'path': path,
      if (kind != null) 'kind': kind,
      if (sha256 != null) 'sha256': sha256,
      if (content != null) 'content': content,
      if (updated != null) 'updated': updated,
      if (device != null) 'device': device,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CareerFileDocsCompanion copyWith({
    Value<String>? id,
    Value<String>? hlc,
    Value<bool>? deleted,
    Value<String>? path,
    Value<String>? kind,
    Value<String>? sha256,
    Value<String>? content,
    Value<String>? updated,
    Value<String>? device,
    Value<int>? rowid,
  }) {
    return CareerFileDocsCompanion(
      id: id ?? this.id,
      hlc: hlc ?? this.hlc,
      deleted: deleted ?? this.deleted,
      path: path ?? this.path,
      kind: kind ?? this.kind,
      sha256: sha256 ?? this.sha256,
      content: content ?? this.content,
      updated: updated ?? this.updated,
      device: device ?? this.device,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (hlc.present) {
      map['hlc'] = Variable<String>(hlc.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (path.present) {
      map['path'] = Variable<String>(path.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (sha256.present) {
      map['sha256'] = Variable<String>(sha256.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (updated.present) {
      map['updated'] = Variable<String>(updated.value);
    }
    if (device.present) {
      map['device'] = Variable<String>(device.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CareerFileDocsCompanion(')
          ..write('id: $id, ')
          ..write('hlc: $hlc, ')
          ..write('deleted: $deleted, ')
          ..write('path: $path, ')
          ..write('kind: $kind, ')
          ..write('sha256: $sha256, ')
          ..write('content: $content, ')
          ..write('updated: $updated, ')
          ..write('device: $device, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CareerSavedSearchesTable extends CareerSavedSearches
    with TableInfo<$CareerSavedSearchesTable, SavedSearchRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CareerSavedSearchesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hlcMeta = const VerificationMeta('hlc');
  @override
  late final GeneratedColumn<String> hlc = GeneratedColumn<String>(
    'hlc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _deletedMeta = const VerificationMeta(
    'deleted',
  );
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
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
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titlesMeta = const VerificationMeta('titles');
  @override
  late final GeneratedColumn<String> titles = GeneratedColumn<String>(
    'titles',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _exactOnlyMeta = const VerificationMeta(
    'exactOnly',
  );
  @override
  late final GeneratedColumn<bool> exactOnly = GeneratedColumn<bool>(
    'exact_only',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("exact_only" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _skillsMeta = const VerificationMeta('skills');
  @override
  late final GeneratedColumn<String> skills = GeneratedColumn<String>(
    'skills',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _notWordsMeta = const VerificationMeta(
    'notWords',
  );
  @override
  late final GeneratedColumn<String> notWords = GeneratedColumn<String>(
    'not_words',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _notEmployersMeta = const VerificationMeta(
    'notEmployers',
  );
  @override
  late final GeneratedColumn<String> notEmployers = GeneratedColumn<String>(
    'not_employers',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _placesMeta = const VerificationMeta('places');
  @override
  late final GeneratedColumn<String> places = GeneratedColumn<String>(
    'places',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _originMeta = const VerificationMeta('origin');
  @override
  late final GeneratedColumn<String> origin = GeneratedColumn<String>(
    'origin',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('user'),
  );
  static const VerificationMeta _createdMeta = const VerificationMeta(
    'created',
  );
  @override
  late final GeneratedColumn<String> created = GeneratedColumn<String>(
    'created',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedMeta = const VerificationMeta(
    'updated',
  );
  @override
  late final GeneratedColumn<String> updated = GeneratedColumn<String>(
    'updated',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastLookedMeta = const VerificationMeta(
    'lastLooked',
  );
  @override
  late final GeneratedColumn<String> lastLooked = GeneratedColumn<String>(
    'last_looked',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _seenMeta = const VerificationMeta('seen');
  @override
  late final GeneratedColumn<String> seen = GeneratedColumn<String>(
    'seen',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    hlc,
    deleted,
    name,
    role,
    titles,
    exactOnly,
    skills,
    notWords,
    notEmployers,
    places,
    origin,
    created,
    updated,
    lastLooked,
    seen,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'career_saved_searches';
  @override
  VerificationContext validateIntegrity(
    Insertable<SavedSearchRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('hlc')) {
      context.handle(
        _hlcMeta,
        hlc.isAcceptableOrUnknown(data['hlc']!, _hlcMeta),
      );
    }
    if (data.containsKey('deleted')) {
      context.handle(
        _deletedMeta,
        deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('titles')) {
      context.handle(
        _titlesMeta,
        titles.isAcceptableOrUnknown(data['titles']!, _titlesMeta),
      );
    }
    if (data.containsKey('exact_only')) {
      context.handle(
        _exactOnlyMeta,
        exactOnly.isAcceptableOrUnknown(data['exact_only']!, _exactOnlyMeta),
      );
    }
    if (data.containsKey('skills')) {
      context.handle(
        _skillsMeta,
        skills.isAcceptableOrUnknown(data['skills']!, _skillsMeta),
      );
    }
    if (data.containsKey('not_words')) {
      context.handle(
        _notWordsMeta,
        notWords.isAcceptableOrUnknown(data['not_words']!, _notWordsMeta),
      );
    }
    if (data.containsKey('not_employers')) {
      context.handle(
        _notEmployersMeta,
        notEmployers.isAcceptableOrUnknown(
          data['not_employers']!,
          _notEmployersMeta,
        ),
      );
    }
    if (data.containsKey('places')) {
      context.handle(
        _placesMeta,
        places.isAcceptableOrUnknown(data['places']!, _placesMeta),
      );
    }
    if (data.containsKey('origin')) {
      context.handle(
        _originMeta,
        origin.isAcceptableOrUnknown(data['origin']!, _originMeta),
      );
    }
    if (data.containsKey('created')) {
      context.handle(
        _createdMeta,
        created.isAcceptableOrUnknown(data['created']!, _createdMeta),
      );
    } else if (isInserting) {
      context.missing(_createdMeta);
    }
    if (data.containsKey('updated')) {
      context.handle(
        _updatedMeta,
        updated.isAcceptableOrUnknown(data['updated']!, _updatedMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedMeta);
    }
    if (data.containsKey('last_looked')) {
      context.handle(
        _lastLookedMeta,
        lastLooked.isAcceptableOrUnknown(data['last_looked']!, _lastLookedMeta),
      );
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
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SavedSearchRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SavedSearchRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      hlc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hlc'],
      )!,
      deleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      )!,
      titles: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}titles'],
      )!,
      exactOnly: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}exact_only'],
      )!,
      skills: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}skills'],
      )!,
      notWords: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}not_words'],
      )!,
      notEmployers: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}not_employers'],
      )!,
      places: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}places'],
      )!,
      origin: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origin'],
      )!,
      created: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created'],
      )!,
      updated: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated'],
      )!,
      lastLooked: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_looked'],
      ),
      seen: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}seen'],
      )!,
    );
  }

  @override
  $CareerSavedSearchesTable createAlias(String alias) {
    return $CareerSavedSearchesTable(attachedDatabase, alias);
  }
}

class SavedSearchRow extends DataClass implements Insertable<SavedSearchRow> {
  final String id;
  final String hlc;
  final bool deleted;

  /// What the person calls it; the role until renamed.
  final String name;

  /// The role as typed.
  final String role;

  /// Family titles as JSON: each FamilyTitle plus "on" (switched on).
  final String titles;

  /// Search the typed title only (family expansion off).
  final bool exactOnly;

  /// Tasks and tools searched as well, JSON list of text.
  final String skills;

  /// Words that rule a job out, JSON list of text.
  final String notWords;

  /// Employers and agencies left out, JSON list of text.
  final String notEmployers;

  /// HomeArea list as JSON; empty: the profile's home areas.
  final String places;

  /// profile (made from a profile keyword or target role, untouched since)
  /// | user (saved or edited by the person).
  final String origin;
  final String created;
  final String updated;

  /// When the person last opened it; null: never.
  final String? lastLooked;

  /// Ids of the listed jobs it matched when last looked at, JSON list, so
  /// the rest count as new.
  final String seen;
  const SavedSearchRow({
    required this.id,
    required this.hlc,
    required this.deleted,
    required this.name,
    required this.role,
    required this.titles,
    required this.exactOnly,
    required this.skills,
    required this.notWords,
    required this.notEmployers,
    required this.places,
    required this.origin,
    required this.created,
    required this.updated,
    this.lastLooked,
    required this.seen,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['hlc'] = Variable<String>(hlc);
    map['deleted'] = Variable<bool>(deleted);
    map['name'] = Variable<String>(name);
    map['role'] = Variable<String>(role);
    map['titles'] = Variable<String>(titles);
    map['exact_only'] = Variable<bool>(exactOnly);
    map['skills'] = Variable<String>(skills);
    map['not_words'] = Variable<String>(notWords);
    map['not_employers'] = Variable<String>(notEmployers);
    map['places'] = Variable<String>(places);
    map['origin'] = Variable<String>(origin);
    map['created'] = Variable<String>(created);
    map['updated'] = Variable<String>(updated);
    if (!nullToAbsent || lastLooked != null) {
      map['last_looked'] = Variable<String>(lastLooked);
    }
    map['seen'] = Variable<String>(seen);
    return map;
  }

  CareerSavedSearchesCompanion toCompanion(bool nullToAbsent) {
    return CareerSavedSearchesCompanion(
      id: Value(id),
      hlc: Value(hlc),
      deleted: Value(deleted),
      name: Value(name),
      role: Value(role),
      titles: Value(titles),
      exactOnly: Value(exactOnly),
      skills: Value(skills),
      notWords: Value(notWords),
      notEmployers: Value(notEmployers),
      places: Value(places),
      origin: Value(origin),
      created: Value(created),
      updated: Value(updated),
      lastLooked: lastLooked == null && nullToAbsent
          ? const Value.absent()
          : Value(lastLooked),
      seen: Value(seen),
    );
  }

  factory SavedSearchRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SavedSearchRow(
      id: serializer.fromJson<String>(json['id']),
      hlc: serializer.fromJson<String>(json['hlc']),
      deleted: serializer.fromJson<bool>(json['deleted']),
      name: serializer.fromJson<String>(json['name']),
      role: serializer.fromJson<String>(json['role']),
      titles: serializer.fromJson<String>(json['titles']),
      exactOnly: serializer.fromJson<bool>(json['exactOnly']),
      skills: serializer.fromJson<String>(json['skills']),
      notWords: serializer.fromJson<String>(json['notWords']),
      notEmployers: serializer.fromJson<String>(json['notEmployers']),
      places: serializer.fromJson<String>(json['places']),
      origin: serializer.fromJson<String>(json['origin']),
      created: serializer.fromJson<String>(json['created']),
      updated: serializer.fromJson<String>(json['updated']),
      lastLooked: serializer.fromJson<String?>(json['lastLooked']),
      seen: serializer.fromJson<String>(json['seen']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'hlc': serializer.toJson<String>(hlc),
      'deleted': serializer.toJson<bool>(deleted),
      'name': serializer.toJson<String>(name),
      'role': serializer.toJson<String>(role),
      'titles': serializer.toJson<String>(titles),
      'exactOnly': serializer.toJson<bool>(exactOnly),
      'skills': serializer.toJson<String>(skills),
      'notWords': serializer.toJson<String>(notWords),
      'notEmployers': serializer.toJson<String>(notEmployers),
      'places': serializer.toJson<String>(places),
      'origin': serializer.toJson<String>(origin),
      'created': serializer.toJson<String>(created),
      'updated': serializer.toJson<String>(updated),
      'lastLooked': serializer.toJson<String?>(lastLooked),
      'seen': serializer.toJson<String>(seen),
    };
  }

  SavedSearchRow copyWith({
    String? id,
    String? hlc,
    bool? deleted,
    String? name,
    String? role,
    String? titles,
    bool? exactOnly,
    String? skills,
    String? notWords,
    String? notEmployers,
    String? places,
    String? origin,
    String? created,
    String? updated,
    Value<String?> lastLooked = const Value.absent(),
    String? seen,
  }) => SavedSearchRow(
    id: id ?? this.id,
    hlc: hlc ?? this.hlc,
    deleted: deleted ?? this.deleted,
    name: name ?? this.name,
    role: role ?? this.role,
    titles: titles ?? this.titles,
    exactOnly: exactOnly ?? this.exactOnly,
    skills: skills ?? this.skills,
    notWords: notWords ?? this.notWords,
    notEmployers: notEmployers ?? this.notEmployers,
    places: places ?? this.places,
    origin: origin ?? this.origin,
    created: created ?? this.created,
    updated: updated ?? this.updated,
    lastLooked: lastLooked.present ? lastLooked.value : this.lastLooked,
    seen: seen ?? this.seen,
  );
  SavedSearchRow copyWithCompanion(CareerSavedSearchesCompanion data) {
    return SavedSearchRow(
      id: data.id.present ? data.id.value : this.id,
      hlc: data.hlc.present ? data.hlc.value : this.hlc,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      name: data.name.present ? data.name.value : this.name,
      role: data.role.present ? data.role.value : this.role,
      titles: data.titles.present ? data.titles.value : this.titles,
      exactOnly: data.exactOnly.present ? data.exactOnly.value : this.exactOnly,
      skills: data.skills.present ? data.skills.value : this.skills,
      notWords: data.notWords.present ? data.notWords.value : this.notWords,
      notEmployers: data.notEmployers.present
          ? data.notEmployers.value
          : this.notEmployers,
      places: data.places.present ? data.places.value : this.places,
      origin: data.origin.present ? data.origin.value : this.origin,
      created: data.created.present ? data.created.value : this.created,
      updated: data.updated.present ? data.updated.value : this.updated,
      lastLooked: data.lastLooked.present
          ? data.lastLooked.value
          : this.lastLooked,
      seen: data.seen.present ? data.seen.value : this.seen,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SavedSearchRow(')
          ..write('id: $id, ')
          ..write('hlc: $hlc, ')
          ..write('deleted: $deleted, ')
          ..write('name: $name, ')
          ..write('role: $role, ')
          ..write('titles: $titles, ')
          ..write('exactOnly: $exactOnly, ')
          ..write('skills: $skills, ')
          ..write('notWords: $notWords, ')
          ..write('notEmployers: $notEmployers, ')
          ..write('places: $places, ')
          ..write('origin: $origin, ')
          ..write('created: $created, ')
          ..write('updated: $updated, ')
          ..write('lastLooked: $lastLooked, ')
          ..write('seen: $seen')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    hlc,
    deleted,
    name,
    role,
    titles,
    exactOnly,
    skills,
    notWords,
    notEmployers,
    places,
    origin,
    created,
    updated,
    lastLooked,
    seen,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SavedSearchRow &&
          other.id == this.id &&
          other.hlc == this.hlc &&
          other.deleted == this.deleted &&
          other.name == this.name &&
          other.role == this.role &&
          other.titles == this.titles &&
          other.exactOnly == this.exactOnly &&
          other.skills == this.skills &&
          other.notWords == this.notWords &&
          other.notEmployers == this.notEmployers &&
          other.places == this.places &&
          other.origin == this.origin &&
          other.created == this.created &&
          other.updated == this.updated &&
          other.lastLooked == this.lastLooked &&
          other.seen == this.seen);
}

class CareerSavedSearchesCompanion extends UpdateCompanion<SavedSearchRow> {
  final Value<String> id;
  final Value<String> hlc;
  final Value<bool> deleted;
  final Value<String> name;
  final Value<String> role;
  final Value<String> titles;
  final Value<bool> exactOnly;
  final Value<String> skills;
  final Value<String> notWords;
  final Value<String> notEmployers;
  final Value<String> places;
  final Value<String> origin;
  final Value<String> created;
  final Value<String> updated;
  final Value<String?> lastLooked;
  final Value<String> seen;
  final Value<int> rowid;
  const CareerSavedSearchesCompanion({
    this.id = const Value.absent(),
    this.hlc = const Value.absent(),
    this.deleted = const Value.absent(),
    this.name = const Value.absent(),
    this.role = const Value.absent(),
    this.titles = const Value.absent(),
    this.exactOnly = const Value.absent(),
    this.skills = const Value.absent(),
    this.notWords = const Value.absent(),
    this.notEmployers = const Value.absent(),
    this.places = const Value.absent(),
    this.origin = const Value.absent(),
    this.created = const Value.absent(),
    this.updated = const Value.absent(),
    this.lastLooked = const Value.absent(),
    this.seen = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CareerSavedSearchesCompanion.insert({
    required String id,
    this.hlc = const Value.absent(),
    this.deleted = const Value.absent(),
    required String name,
    required String role,
    this.titles = const Value.absent(),
    this.exactOnly = const Value.absent(),
    this.skills = const Value.absent(),
    this.notWords = const Value.absent(),
    this.notEmployers = const Value.absent(),
    this.places = const Value.absent(),
    this.origin = const Value.absent(),
    required String created,
    required String updated,
    this.lastLooked = const Value.absent(),
    this.seen = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       role = Value(role),
       created = Value(created),
       updated = Value(updated);
  static Insertable<SavedSearchRow> custom({
    Expression<String>? id,
    Expression<String>? hlc,
    Expression<bool>? deleted,
    Expression<String>? name,
    Expression<String>? role,
    Expression<String>? titles,
    Expression<bool>? exactOnly,
    Expression<String>? skills,
    Expression<String>? notWords,
    Expression<String>? notEmployers,
    Expression<String>? places,
    Expression<String>? origin,
    Expression<String>? created,
    Expression<String>? updated,
    Expression<String>? lastLooked,
    Expression<String>? seen,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (hlc != null) 'hlc': hlc,
      if (deleted != null) 'deleted': deleted,
      if (name != null) 'name': name,
      if (role != null) 'role': role,
      if (titles != null) 'titles': titles,
      if (exactOnly != null) 'exact_only': exactOnly,
      if (skills != null) 'skills': skills,
      if (notWords != null) 'not_words': notWords,
      if (notEmployers != null) 'not_employers': notEmployers,
      if (places != null) 'places': places,
      if (origin != null) 'origin': origin,
      if (created != null) 'created': created,
      if (updated != null) 'updated': updated,
      if (lastLooked != null) 'last_looked': lastLooked,
      if (seen != null) 'seen': seen,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CareerSavedSearchesCompanion copyWith({
    Value<String>? id,
    Value<String>? hlc,
    Value<bool>? deleted,
    Value<String>? name,
    Value<String>? role,
    Value<String>? titles,
    Value<bool>? exactOnly,
    Value<String>? skills,
    Value<String>? notWords,
    Value<String>? notEmployers,
    Value<String>? places,
    Value<String>? origin,
    Value<String>? created,
    Value<String>? updated,
    Value<String?>? lastLooked,
    Value<String>? seen,
    Value<int>? rowid,
  }) {
    return CareerSavedSearchesCompanion(
      id: id ?? this.id,
      hlc: hlc ?? this.hlc,
      deleted: deleted ?? this.deleted,
      name: name ?? this.name,
      role: role ?? this.role,
      titles: titles ?? this.titles,
      exactOnly: exactOnly ?? this.exactOnly,
      skills: skills ?? this.skills,
      notWords: notWords ?? this.notWords,
      notEmployers: notEmployers ?? this.notEmployers,
      places: places ?? this.places,
      origin: origin ?? this.origin,
      created: created ?? this.created,
      updated: updated ?? this.updated,
      lastLooked: lastLooked ?? this.lastLooked,
      seen: seen ?? this.seen,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (hlc.present) {
      map['hlc'] = Variable<String>(hlc.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (titles.present) {
      map['titles'] = Variable<String>(titles.value);
    }
    if (exactOnly.present) {
      map['exact_only'] = Variable<bool>(exactOnly.value);
    }
    if (skills.present) {
      map['skills'] = Variable<String>(skills.value);
    }
    if (notWords.present) {
      map['not_words'] = Variable<String>(notWords.value);
    }
    if (notEmployers.present) {
      map['not_employers'] = Variable<String>(notEmployers.value);
    }
    if (places.present) {
      map['places'] = Variable<String>(places.value);
    }
    if (origin.present) {
      map['origin'] = Variable<String>(origin.value);
    }
    if (created.present) {
      map['created'] = Variable<String>(created.value);
    }
    if (updated.present) {
      map['updated'] = Variable<String>(updated.value);
    }
    if (lastLooked.present) {
      map['last_looked'] = Variable<String>(lastLooked.value);
    }
    if (seen.present) {
      map['seen'] = Variable<String>(seen.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CareerSavedSearchesCompanion(')
          ..write('id: $id, ')
          ..write('hlc: $hlc, ')
          ..write('deleted: $deleted, ')
          ..write('name: $name, ')
          ..write('role: $role, ')
          ..write('titles: $titles, ')
          ..write('exactOnly: $exactOnly, ')
          ..write('skills: $skills, ')
          ..write('notWords: $notWords, ')
          ..write('notEmployers: $notEmployers, ')
          ..write('places: $places, ')
          ..write('origin: $origin, ')
          ..write('created: $created, ')
          ..write('updated: $updated, ')
          ..write('lastLooked: $lastLooked, ')
          ..write('seen: $seen, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PrefsTable extends Prefs with TableInfo<$PrefsTable, Pref> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PrefsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hlcMeta = const VerificationMeta('hlc');
  @override
  late final GeneratedColumn<String> hlc = GeneratedColumn<String>(
    'hlc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _deletedMeta = const VerificationMeta(
    'deleted',
  );
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, hlc, deleted, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'prefs';
  @override
  VerificationContext validateIntegrity(
    Insertable<Pref> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('hlc')) {
      context.handle(
        _hlcMeta,
        hlc.isAcceptableOrUnknown(data['hlc']!, _hlcMeta),
      );
    }
    if (data.containsKey('deleted')) {
      context.handle(
        _deletedMeta,
        deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta),
      );
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Pref map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Pref(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      hlc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hlc'],
      )!,
      deleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $PrefsTable createAlias(String alias) {
    return $PrefsTable(attachedDatabase, alias);
  }
}

class Pref extends DataClass implements Insertable<Pref> {
  final String id;
  final String hlc;
  final bool deleted;
  final String value;
  const Pref({
    required this.id,
    required this.hlc,
    required this.deleted,
    required this.value,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['hlc'] = Variable<String>(hlc);
    map['deleted'] = Variable<bool>(deleted);
    map['value'] = Variable<String>(value);
    return map;
  }

  PrefsCompanion toCompanion(bool nullToAbsent) {
    return PrefsCompanion(
      id: Value(id),
      hlc: Value(hlc),
      deleted: Value(deleted),
      value: Value(value),
    );
  }

  factory Pref.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Pref(
      id: serializer.fromJson<String>(json['id']),
      hlc: serializer.fromJson<String>(json['hlc']),
      deleted: serializer.fromJson<bool>(json['deleted']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'hlc': serializer.toJson<String>(hlc),
      'deleted': serializer.toJson<bool>(deleted),
      'value': serializer.toJson<String>(value),
    };
  }

  Pref copyWith({String? id, String? hlc, bool? deleted, String? value}) =>
      Pref(
        id: id ?? this.id,
        hlc: hlc ?? this.hlc,
        deleted: deleted ?? this.deleted,
        value: value ?? this.value,
      );
  Pref copyWithCompanion(PrefsCompanion data) {
    return Pref(
      id: data.id.present ? data.id.value : this.id,
      hlc: data.hlc.present ? data.hlc.value : this.hlc,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Pref(')
          ..write('id: $id, ')
          ..write('hlc: $hlc, ')
          ..write('deleted: $deleted, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, hlc, deleted, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Pref &&
          other.id == this.id &&
          other.hlc == this.hlc &&
          other.deleted == this.deleted &&
          other.value == this.value);
}

class PrefsCompanion extends UpdateCompanion<Pref> {
  final Value<String> id;
  final Value<String> hlc;
  final Value<bool> deleted;
  final Value<String> value;
  final Value<int> rowid;
  const PrefsCompanion({
    this.id = const Value.absent(),
    this.hlc = const Value.absent(),
    this.deleted = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PrefsCompanion.insert({
    required String id,
    this.hlc = const Value.absent(),
    this.deleted = const Value.absent(),
    required String value,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       value = Value(value);
  static Insertable<Pref> custom({
    Expression<String>? id,
    Expression<String>? hlc,
    Expression<bool>? deleted,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (hlc != null) 'hlc': hlc,
      if (deleted != null) 'deleted': deleted,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PrefsCompanion copyWith({
    Value<String>? id,
    Value<String>? hlc,
    Value<bool>? deleted,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return PrefsCompanion(
      id: id ?? this.id,
      hlc: hlc ?? this.hlc,
      deleted: deleted ?? this.deleted,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (hlc.present) {
      map['hlc'] = Variable<String>(hlc.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PrefsCompanion(')
          ..write('id: $id, ')
          ..write('hlc: $hlc, ')
          ..write('deleted: $deleted, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OutboxTable extends Outbox with TableInfo<$OutboxTable, OutboxItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OutboxTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _entityMeta = const VerificationMeta('entity');
  @override
  late final GeneratedColumn<String> entity = GeneratedColumn<String>(
    'entity',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rowIdMeta = const VerificationMeta('rowId');
  @override
  late final GeneratedColumn<String> rowId = GeneratedColumn<String>(
    'row_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _seqMeta = const VerificationMeta('seq');
  @override
  late final GeneratedColumn<int> seq = GeneratedColumn<int>(
    'seq',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [entity, rowId, seq];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'outbox';
  @override
  VerificationContext validateIntegrity(
    Insertable<OutboxItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('entity')) {
      context.handle(
        _entityMeta,
        entity.isAcceptableOrUnknown(data['entity']!, _entityMeta),
      );
    } else if (isInserting) {
      context.missing(_entityMeta);
    }
    if (data.containsKey('row_id')) {
      context.handle(
        _rowIdMeta,
        rowId.isAcceptableOrUnknown(data['row_id']!, _rowIdMeta),
      );
    } else if (isInserting) {
      context.missing(_rowIdMeta);
    }
    if (data.containsKey('seq')) {
      context.handle(
        _seqMeta,
        seq.isAcceptableOrUnknown(data['seq']!, _seqMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {entity, rowId};
  @override
  OutboxItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OutboxItem(
      entity: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity'],
      )!,
      rowId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}row_id'],
      )!,
      seq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seq'],
      ),
    );
  }

  @override
  $OutboxTable createAlias(String alias) {
    return $OutboxTable(attachedDatabase, alias);
  }
}

class OutboxItem extends DataClass implements Insertable<OutboxItem> {
  final String entity;
  final String rowId;
  final int? seq;
  const OutboxItem({required this.entity, required this.rowId, this.seq});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['entity'] = Variable<String>(entity);
    map['row_id'] = Variable<String>(rowId);
    if (!nullToAbsent || seq != null) {
      map['seq'] = Variable<int>(seq);
    }
    return map;
  }

  OutboxCompanion toCompanion(bool nullToAbsent) {
    return OutboxCompanion(
      entity: Value(entity),
      rowId: Value(rowId),
      seq: seq == null && nullToAbsent ? const Value.absent() : Value(seq),
    );
  }

  factory OutboxItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OutboxItem(
      entity: serializer.fromJson<String>(json['entity']),
      rowId: serializer.fromJson<String>(json['rowId']),
      seq: serializer.fromJson<int?>(json['seq']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'entity': serializer.toJson<String>(entity),
      'rowId': serializer.toJson<String>(rowId),
      'seq': serializer.toJson<int?>(seq),
    };
  }

  OutboxItem copyWith({
    String? entity,
    String? rowId,
    Value<int?> seq = const Value.absent(),
  }) => OutboxItem(
    entity: entity ?? this.entity,
    rowId: rowId ?? this.rowId,
    seq: seq.present ? seq.value : this.seq,
  );
  OutboxItem copyWithCompanion(OutboxCompanion data) {
    return OutboxItem(
      entity: data.entity.present ? data.entity.value : this.entity,
      rowId: data.rowId.present ? data.rowId.value : this.rowId,
      seq: data.seq.present ? data.seq.value : this.seq,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OutboxItem(')
          ..write('entity: $entity, ')
          ..write('rowId: $rowId, ')
          ..write('seq: $seq')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(entity, rowId, seq);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OutboxItem &&
          other.entity == this.entity &&
          other.rowId == this.rowId &&
          other.seq == this.seq);
}

class OutboxCompanion extends UpdateCompanion<OutboxItem> {
  final Value<String> entity;
  final Value<String> rowId;
  final Value<int?> seq;
  final Value<int> rowid;
  const OutboxCompanion({
    this.entity = const Value.absent(),
    this.rowId = const Value.absent(),
    this.seq = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OutboxCompanion.insert({
    required String entity,
    required String rowId,
    this.seq = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : entity = Value(entity),
       rowId = Value(rowId);
  static Insertable<OutboxItem> custom({
    Expression<String>? entity,
    Expression<String>? rowId,
    Expression<int>? seq,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (entity != null) 'entity': entity,
      if (rowId != null) 'row_id': rowId,
      if (seq != null) 'seq': seq,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OutboxCompanion copyWith({
    Value<String>? entity,
    Value<String>? rowId,
    Value<int?>? seq,
    Value<int>? rowid,
  }) {
    return OutboxCompanion(
      entity: entity ?? this.entity,
      rowId: rowId ?? this.rowId,
      seq: seq ?? this.seq,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (entity.present) {
      map['entity'] = Variable<String>(entity.value);
    }
    if (rowId.present) {
      map['row_id'] = Variable<String>(rowId.value);
    }
    if (seq.present) {
      map['seq'] = Variable<int>(seq.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OutboxCompanion(')
          ..write('entity: $entity, ')
          ..write('rowId: $rowId, ')
          ..write('seq: $seq, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncCursorsTable extends SyncCursors
    with TableInfo<$SyncCursorsTable, SyncCursor> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncCursorsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _seqMeta = const VerificationMeta('seq');
  @override
  late final GeneratedColumn<int> seq = GeneratedColumn<int>(
    'seq',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [deviceId, seq];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_cursors';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncCursor> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('seq')) {
      context.handle(
        _seqMeta,
        seq.isAcceptableOrUnknown(data['seq']!, _seqMeta),
      );
    } else if (isInserting) {
      context.missing(_seqMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {deviceId};
  @override
  SyncCursor map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncCursor(
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      seq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seq'],
      )!,
    );
  }

  @override
  $SyncCursorsTable createAlias(String alias) {
    return $SyncCursorsTable(attachedDatabase, alias);
  }
}

class SyncCursor extends DataClass implements Insertable<SyncCursor> {
  final String deviceId;
  final int seq;
  const SyncCursor({required this.deviceId, required this.seq});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['device_id'] = Variable<String>(deviceId);
    map['seq'] = Variable<int>(seq);
    return map;
  }

  SyncCursorsCompanion toCompanion(bool nullToAbsent) {
    return SyncCursorsCompanion(deviceId: Value(deviceId), seq: Value(seq));
  }

  factory SyncCursor.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncCursor(
      deviceId: serializer.fromJson<String>(json['deviceId']),
      seq: serializer.fromJson<int>(json['seq']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'deviceId': serializer.toJson<String>(deviceId),
      'seq': serializer.toJson<int>(seq),
    };
  }

  SyncCursor copyWith({String? deviceId, int? seq}) =>
      SyncCursor(deviceId: deviceId ?? this.deviceId, seq: seq ?? this.seq);
  SyncCursor copyWithCompanion(SyncCursorsCompanion data) {
    return SyncCursor(
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      seq: data.seq.present ? data.seq.value : this.seq,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncCursor(')
          ..write('deviceId: $deviceId, ')
          ..write('seq: $seq')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(deviceId, seq);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncCursor &&
          other.deviceId == this.deviceId &&
          other.seq == this.seq);
}

class SyncCursorsCompanion extends UpdateCompanion<SyncCursor> {
  final Value<String> deviceId;
  final Value<int> seq;
  final Value<int> rowid;
  const SyncCursorsCompanion({
    this.deviceId = const Value.absent(),
    this.seq = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncCursorsCompanion.insert({
    required String deviceId,
    required int seq,
    this.rowid = const Value.absent(),
  }) : deviceId = Value(deviceId),
       seq = Value(seq);
  static Insertable<SyncCursor> custom({
    Expression<String>? deviceId,
    Expression<int>? seq,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (deviceId != null) 'device_id': deviceId,
      if (seq != null) 'seq': seq,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncCursorsCompanion copyWith({
    Value<String>? deviceId,
    Value<int>? seq,
    Value<int>? rowid,
  }) {
    return SyncCursorsCompanion(
      deviceId: deviceId ?? this.deviceId,
      seq: seq ?? this.seq,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (seq.present) {
      map['seq'] = Variable<int>(seq.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncCursorsCompanion(')
          ..write('deviceId: $deviceId, ')
          ..write('seq: $seq, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalSettingsTable extends LocalSettings
    with TableInfo<$LocalSettingsTable, LocalSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalSetting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  LocalSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalSetting(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $LocalSettingsTable createAlias(String alias) {
    return $LocalSettingsTable(attachedDatabase, alias);
  }
}

class LocalSetting extends DataClass implements Insertable<LocalSetting> {
  final String key;
  final String value;
  const LocalSetting({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  LocalSettingsCompanion toCompanion(bool nullToAbsent) {
    return LocalSettingsCompanion(key: Value(key), value: Value(value));
  }

  factory LocalSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalSetting(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  LocalSetting copyWith({String? key, String? value}) =>
      LocalSetting(key: key ?? this.key, value: value ?? this.value);
  LocalSetting copyWithCompanion(LocalSettingsCompanion data) {
    return LocalSetting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalSetting(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalSetting &&
          other.key == this.key &&
          other.value == this.value);
}

class LocalSettingsCompanion extends UpdateCompanion<LocalSetting> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const LocalSettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalSettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<LocalSetting> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalSettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return LocalSettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalSettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $JobListingsTable jobListings = $JobListingsTable(this);
  late final $JobApplicationsTable jobApplications = $JobApplicationsTable(
    this,
  );
  late final $JobEventsTable jobEvents = $JobEventsTable(this);
  late final $JobChecksTable jobChecks = $JobChecksTable(this);
  late final $JobArchiveTable jobArchive = $JobArchiveTable(this);
  late final $CareerContactsTable careerContacts = $CareerContactsTable(this);
  late final $CareerResumesTable careerResumes = $CareerResumesTable(this);
  late final $CareerReportsTable careerReports = $CareerReportsTable(this);
  late final $CareerGrowthTable careerGrowth = $CareerGrowthTable(this);
  late final $CareerPracticeTable careerPractice = $CareerPracticeTable(this);
  late final $CareerAnswersTable careerAnswers = $CareerAnswersTable(this);
  late final $CareerDocumentsTable careerDocuments = $CareerDocumentsTable(
    this,
  );
  late final $CareerQuestionsTable careerQuestions = $CareerQuestionsTable(
    this,
  );
  late final $CareerJournalTable careerJournal = $CareerJournalTable(this);
  late final $CareerStoriesTable careerStories = $CareerStoriesTable(this);
  late final $ContactHandlesTable contactHandles = $ContactHandlesTable(this);
  late final $ConversationsTable conversations = $ConversationsTable(this);
  late final $MessagesTable messages = $MessagesTable(this);
  late final $CareerPostsTable careerPosts = $CareerPostsTable(this);
  late final $CareerTracksTable careerTracks = $CareerTracksTable(this);
  late final $CareerRoleProfilesTable careerRoleProfiles =
      $CareerRoleProfilesTable(this);
  late final $CareerProcessesTable careerProcesses = $CareerProcessesTable(
    this,
  );
  late final $BridgeStudyPlansTable bridgeStudyPlans = $BridgeStudyPlansTable(
    this,
  );
  late final $BridgeStudyProgressTable bridgeStudyProgress =
      $BridgeStudyProgressTable(this);
  late final $CareerFileDocsTable careerFileDocs = $CareerFileDocsTable(this);
  late final $CareerSavedSearchesTable careerSavedSearches =
      $CareerSavedSearchesTable(this);
  late final $PrefsTable prefs = $PrefsTable(this);
  late final $OutboxTable outbox = $OutboxTable(this);
  late final $SyncCursorsTable syncCursors = $SyncCursorsTable(this);
  late final $LocalSettingsTable localSettings = $LocalSettingsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    jobListings,
    jobApplications,
    jobEvents,
    jobChecks,
    jobArchive,
    careerContacts,
    careerResumes,
    careerReports,
    careerGrowth,
    careerPractice,
    careerAnswers,
    careerDocuments,
    careerQuestions,
    careerJournal,
    careerStories,
    contactHandles,
    conversations,
    messages,
    careerPosts,
    careerTracks,
    careerRoleProfiles,
    careerProcesses,
    bridgeStudyPlans,
    bridgeStudyProgress,
    careerFileDocs,
    careerSavedSearches,
    prefs,
    outbox,
    syncCursors,
    localSettings,
  ];
}

typedef $$JobListingsTableCreateCompanionBuilder =
    JobListingsCompanion Function({
      required String id,
      Value<String> hlc,
      Value<bool> deleted,
      required String title,
      Value<String> company,
      Value<String> location,
      Value<String> country,
      Value<bool> remote,
      Value<int?> salaryMin,
      Value<int?> salaryMax,
      Value<String> currency,
      Value<String> salaryText,
      Value<String> url,
      Value<String> description,
      Value<String?> posted,
      Value<String?> closing,
      Value<String> source,
      Value<String> sourceId,
      required String found,
      Value<String> status,
      Value<int?> fit,
      Value<String> fitBy,
      Value<String> assessment,
      Value<String> notes,
      Value<int> rowid,
    });
typedef $$JobListingsTableUpdateCompanionBuilder =
    JobListingsCompanion Function({
      Value<String> id,
      Value<String> hlc,
      Value<bool> deleted,
      Value<String> title,
      Value<String> company,
      Value<String> location,
      Value<String> country,
      Value<bool> remote,
      Value<int?> salaryMin,
      Value<int?> salaryMax,
      Value<String> currency,
      Value<String> salaryText,
      Value<String> url,
      Value<String> description,
      Value<String?> posted,
      Value<String?> closing,
      Value<String> source,
      Value<String> sourceId,
      Value<String> found,
      Value<String> status,
      Value<int?> fit,
      Value<String> fitBy,
      Value<String> assessment,
      Value<String> notes,
      Value<int> rowid,
    });

class $$JobListingsTableFilterComposer
    extends Composer<_$AppDatabase, $JobListingsTable> {
  $$JobListingsTableFilterComposer({
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

  ColumnFilters<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get company => $composableBuilder(
    column: $table.company,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get country => $composableBuilder(
    column: $table.country,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get remote => $composableBuilder(
    column: $table.remote,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get salaryMin => $composableBuilder(
    column: $table.salaryMin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get salaryMax => $composableBuilder(
    column: $table.salaryMax,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get salaryText => $composableBuilder(
    column: $table.salaryText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get posted => $composableBuilder(
    column: $table.posted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get closing => $composableBuilder(
    column: $table.closing,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get found => $composableBuilder(
    column: $table.found,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fit => $composableBuilder(
    column: $table.fit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fitBy => $composableBuilder(
    column: $table.fitBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get assessment => $composableBuilder(
    column: $table.assessment,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );
}

class $$JobListingsTableOrderingComposer
    extends Composer<_$AppDatabase, $JobListingsTable> {
  $$JobListingsTableOrderingComposer({
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

  ColumnOrderings<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get company => $composableBuilder(
    column: $table.company,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get country => $composableBuilder(
    column: $table.country,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get remote => $composableBuilder(
    column: $table.remote,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get salaryMin => $composableBuilder(
    column: $table.salaryMin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get salaryMax => $composableBuilder(
    column: $table.salaryMax,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get salaryText => $composableBuilder(
    column: $table.salaryText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get posted => $composableBuilder(
    column: $table.posted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get closing => $composableBuilder(
    column: $table.closing,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get found => $composableBuilder(
    column: $table.found,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fit => $composableBuilder(
    column: $table.fit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fitBy => $composableBuilder(
    column: $table.fitBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get assessment => $composableBuilder(
    column: $table.assessment,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$JobListingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $JobListingsTable> {
  $$JobListingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get hlc =>
      $composableBuilder(column: $table.hlc, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get company =>
      $composableBuilder(column: $table.company, builder: (column) => column);

  GeneratedColumn<String> get location =>
      $composableBuilder(column: $table.location, builder: (column) => column);

  GeneratedColumn<String> get country =>
      $composableBuilder(column: $table.country, builder: (column) => column);

  GeneratedColumn<bool> get remote =>
      $composableBuilder(column: $table.remote, builder: (column) => column);

  GeneratedColumn<int> get salaryMin =>
      $composableBuilder(column: $table.salaryMin, builder: (column) => column);

  GeneratedColumn<int> get salaryMax =>
      $composableBuilder(column: $table.salaryMax, builder: (column) => column);

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<String> get salaryText => $composableBuilder(
    column: $table.salaryText,
    builder: (column) => column,
  );

  GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get posted =>
      $composableBuilder(column: $table.posted, builder: (column) => column);

  GeneratedColumn<String> get closing =>
      $composableBuilder(column: $table.closing, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get sourceId =>
      $composableBuilder(column: $table.sourceId, builder: (column) => column);

  GeneratedColumn<String> get found =>
      $composableBuilder(column: $table.found, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get fit =>
      $composableBuilder(column: $table.fit, builder: (column) => column);

  GeneratedColumn<String> get fitBy =>
      $composableBuilder(column: $table.fitBy, builder: (column) => column);

  GeneratedColumn<String> get assessment => $composableBuilder(
    column: $table.assessment,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);
}

class $$JobListingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $JobListingsTable,
          Job,
          $$JobListingsTableFilterComposer,
          $$JobListingsTableOrderingComposer,
          $$JobListingsTableAnnotationComposer,
          $$JobListingsTableCreateCompanionBuilder,
          $$JobListingsTableUpdateCompanionBuilder,
          (Job, BaseReferences<_$AppDatabase, $JobListingsTable, Job>),
          Job,
          PrefetchHooks Function()
        > {
  $$JobListingsTableTableManager(_$AppDatabase db, $JobListingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$JobListingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$JobListingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$JobListingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> hlc = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> company = const Value.absent(),
                Value<String> location = const Value.absent(),
                Value<String> country = const Value.absent(),
                Value<bool> remote = const Value.absent(),
                Value<int?> salaryMin = const Value.absent(),
                Value<int?> salaryMax = const Value.absent(),
                Value<String> currency = const Value.absent(),
                Value<String> salaryText = const Value.absent(),
                Value<String> url = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<String?> posted = const Value.absent(),
                Value<String?> closing = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String> sourceId = const Value.absent(),
                Value<String> found = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int?> fit = const Value.absent(),
                Value<String> fitBy = const Value.absent(),
                Value<String> assessment = const Value.absent(),
                Value<String> notes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => JobListingsCompanion(
                id: id,
                hlc: hlc,
                deleted: deleted,
                title: title,
                company: company,
                location: location,
                country: country,
                remote: remote,
                salaryMin: salaryMin,
                salaryMax: salaryMax,
                currency: currency,
                salaryText: salaryText,
                url: url,
                description: description,
                posted: posted,
                closing: closing,
                source: source,
                sourceId: sourceId,
                found: found,
                status: status,
                fit: fit,
                fitBy: fitBy,
                assessment: assessment,
                notes: notes,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String> hlc = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                required String title,
                Value<String> company = const Value.absent(),
                Value<String> location = const Value.absent(),
                Value<String> country = const Value.absent(),
                Value<bool> remote = const Value.absent(),
                Value<int?> salaryMin = const Value.absent(),
                Value<int?> salaryMax = const Value.absent(),
                Value<String> currency = const Value.absent(),
                Value<String> salaryText = const Value.absent(),
                Value<String> url = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<String?> posted = const Value.absent(),
                Value<String?> closing = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String> sourceId = const Value.absent(),
                required String found,
                Value<String> status = const Value.absent(),
                Value<int?> fit = const Value.absent(),
                Value<String> fitBy = const Value.absent(),
                Value<String> assessment = const Value.absent(),
                Value<String> notes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => JobListingsCompanion.insert(
                id: id,
                hlc: hlc,
                deleted: deleted,
                title: title,
                company: company,
                location: location,
                country: country,
                remote: remote,
                salaryMin: salaryMin,
                salaryMax: salaryMax,
                currency: currency,
                salaryText: salaryText,
                url: url,
                description: description,
                posted: posted,
                closing: closing,
                source: source,
                sourceId: sourceId,
                found: found,
                status: status,
                fit: fit,
                fitBy: fitBy,
                assessment: assessment,
                notes: notes,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$JobListingsTable, Job>(table),
                  BaseReferences<_$AppDatabase, $JobListingsTable, Job>(
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

typedef $$JobListingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $JobListingsTable,
      Job,
      $$JobListingsTableFilterComposer,
      $$JobListingsTableOrderingComposer,
      $$JobListingsTableAnnotationComposer,
      $$JobListingsTableCreateCompanionBuilder,
      $$JobListingsTableUpdateCompanionBuilder,
      (Job, BaseReferences<_$AppDatabase, $JobListingsTable, Job>),
      Job,
      PrefetchHooks Function()
    >;
typedef $$JobApplicationsTableCreateCompanionBuilder =
    JobApplicationsCompanion Function({
      required String id,
      Value<String> hlc,
      Value<bool> deleted,
      Value<String?> jobId,
      required String title,
      Value<String> company,
      Value<String> location,
      Value<String> url,
      Value<String> stage,
      Value<String?> applied,
      Value<String?> followUp,
      Value<String> followUpNote,
      Value<String?> resumeId,
      Value<String> reference,
      Value<String> notes,
      required String updated,
      Value<int> rowid,
    });
typedef $$JobApplicationsTableUpdateCompanionBuilder =
    JobApplicationsCompanion Function({
      Value<String> id,
      Value<String> hlc,
      Value<bool> deleted,
      Value<String?> jobId,
      Value<String> title,
      Value<String> company,
      Value<String> location,
      Value<String> url,
      Value<String> stage,
      Value<String?> applied,
      Value<String?> followUp,
      Value<String> followUpNote,
      Value<String?> resumeId,
      Value<String> reference,
      Value<String> notes,
      Value<String> updated,
      Value<int> rowid,
    });

class $$JobApplicationsTableFilterComposer
    extends Composer<_$AppDatabase, $JobApplicationsTable> {
  $$JobApplicationsTableFilterComposer({
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

  ColumnFilters<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get jobId => $composableBuilder(
    column: $table.jobId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get company => $composableBuilder(
    column: $table.company,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get stage => $composableBuilder(
    column: $table.stage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get applied => $composableBuilder(
    column: $table.applied,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get followUp => $composableBuilder(
    column: $table.followUp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get followUpNote => $composableBuilder(
    column: $table.followUpNote,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get resumeId => $composableBuilder(
    column: $table.resumeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reference => $composableBuilder(
    column: $table.reference,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updated => $composableBuilder(
    column: $table.updated,
    builder: (column) => ColumnFilters(column),
  );
}

class $$JobApplicationsTableOrderingComposer
    extends Composer<_$AppDatabase, $JobApplicationsTable> {
  $$JobApplicationsTableOrderingComposer({
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

  ColumnOrderings<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get jobId => $composableBuilder(
    column: $table.jobId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get company => $composableBuilder(
    column: $table.company,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stage => $composableBuilder(
    column: $table.stage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get applied => $composableBuilder(
    column: $table.applied,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get followUp => $composableBuilder(
    column: $table.followUp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get followUpNote => $composableBuilder(
    column: $table.followUpNote,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get resumeId => $composableBuilder(
    column: $table.resumeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reference => $composableBuilder(
    column: $table.reference,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updated => $composableBuilder(
    column: $table.updated,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$JobApplicationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $JobApplicationsTable> {
  $$JobApplicationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get hlc =>
      $composableBuilder(column: $table.hlc, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<String> get jobId =>
      $composableBuilder(column: $table.jobId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get company =>
      $composableBuilder(column: $table.company, builder: (column) => column);

  GeneratedColumn<String> get location =>
      $composableBuilder(column: $table.location, builder: (column) => column);

  GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  GeneratedColumn<String> get stage =>
      $composableBuilder(column: $table.stage, builder: (column) => column);

  GeneratedColumn<String> get applied =>
      $composableBuilder(column: $table.applied, builder: (column) => column);

  GeneratedColumn<String> get followUp =>
      $composableBuilder(column: $table.followUp, builder: (column) => column);

  GeneratedColumn<String> get followUpNote => $composableBuilder(
    column: $table.followUpNote,
    builder: (column) => column,
  );

  GeneratedColumn<String> get resumeId =>
      $composableBuilder(column: $table.resumeId, builder: (column) => column);

  GeneratedColumn<String> get reference =>
      $composableBuilder(column: $table.reference, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get updated =>
      $composableBuilder(column: $table.updated, builder: (column) => column);
}

class $$JobApplicationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $JobApplicationsTable,
          JobApplication,
          $$JobApplicationsTableFilterComposer,
          $$JobApplicationsTableOrderingComposer,
          $$JobApplicationsTableAnnotationComposer,
          $$JobApplicationsTableCreateCompanionBuilder,
          $$JobApplicationsTableUpdateCompanionBuilder,
          (
            JobApplication,
            BaseReferences<
              _$AppDatabase,
              $JobApplicationsTable,
              JobApplication
            >,
          ),
          JobApplication,
          PrefetchHooks Function()
        > {
  $$JobApplicationsTableTableManager(
    _$AppDatabase db,
    $JobApplicationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$JobApplicationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$JobApplicationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$JobApplicationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> hlc = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<String?> jobId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> company = const Value.absent(),
                Value<String> location = const Value.absent(),
                Value<String> url = const Value.absent(),
                Value<String> stage = const Value.absent(),
                Value<String?> applied = const Value.absent(),
                Value<String?> followUp = const Value.absent(),
                Value<String> followUpNote = const Value.absent(),
                Value<String?> resumeId = const Value.absent(),
                Value<String> reference = const Value.absent(),
                Value<String> notes = const Value.absent(),
                Value<String> updated = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => JobApplicationsCompanion(
                id: id,
                hlc: hlc,
                deleted: deleted,
                jobId: jobId,
                title: title,
                company: company,
                location: location,
                url: url,
                stage: stage,
                applied: applied,
                followUp: followUp,
                followUpNote: followUpNote,
                resumeId: resumeId,
                reference: reference,
                notes: notes,
                updated: updated,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String> hlc = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<String?> jobId = const Value.absent(),
                required String title,
                Value<String> company = const Value.absent(),
                Value<String> location = const Value.absent(),
                Value<String> url = const Value.absent(),
                Value<String> stage = const Value.absent(),
                Value<String?> applied = const Value.absent(),
                Value<String?> followUp = const Value.absent(),
                Value<String> followUpNote = const Value.absent(),
                Value<String?> resumeId = const Value.absent(),
                Value<String> reference = const Value.absent(),
                Value<String> notes = const Value.absent(),
                required String updated,
                Value<int> rowid = const Value.absent(),
              }) => JobApplicationsCompanion.insert(
                id: id,
                hlc: hlc,
                deleted: deleted,
                jobId: jobId,
                title: title,
                company: company,
                location: location,
                url: url,
                stage: stage,
                applied: applied,
                followUp: followUp,
                followUpNote: followUpNote,
                resumeId: resumeId,
                reference: reference,
                notes: notes,
                updated: updated,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$JobApplicationsTable, JobApplication>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $JobApplicationsTable,
                    JobApplication
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$JobApplicationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $JobApplicationsTable,
      JobApplication,
      $$JobApplicationsTableFilterComposer,
      $$JobApplicationsTableOrderingComposer,
      $$JobApplicationsTableAnnotationComposer,
      $$JobApplicationsTableCreateCompanionBuilder,
      $$JobApplicationsTableUpdateCompanionBuilder,
      (
        JobApplication,
        BaseReferences<_$AppDatabase, $JobApplicationsTable, JobApplication>,
      ),
      JobApplication,
      PrefetchHooks Function()
    >;
typedef $$JobEventsTableCreateCompanionBuilder = JobEventsCompanion Function({
  required String id,
  Value<String> hlc,
  Value<bool> deleted,
  required String applicationId,
  required String at,
  required String kind,
  Value<String> summary,
  Value<int> rowid,
});
typedef $$JobEventsTableUpdateCompanionBuilder = JobEventsCompanion Function({
  Value<String> id,
  Value<String> hlc,
  Value<bool> deleted,
  Value<String> applicationId,
  Value<String> at,
  Value<String> kind,
  Value<String> summary,
  Value<int> rowid,
});

class $$JobEventsTableFilterComposer
    extends Composer<_$AppDatabase, $JobEventsTable> {
  $$JobEventsTableFilterComposer({
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

  ColumnFilters<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get applicationId => $composableBuilder(
    column: $table.applicationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get summary => $composableBuilder(
    column: $table.summary,
    builder: (column) => ColumnFilters(column),
  );
}

class $$JobEventsTableOrderingComposer
    extends Composer<_$AppDatabase, $JobEventsTable> {
  $$JobEventsTableOrderingComposer({
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

  ColumnOrderings<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get applicationId => $composableBuilder(
    column: $table.applicationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get summary => $composableBuilder(
    column: $table.summary,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$JobEventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $JobEventsTable> {
  $$JobEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get hlc =>
      $composableBuilder(column: $table.hlc, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<String> get applicationId => $composableBuilder(
    column: $table.applicationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get at =>
      $composableBuilder(column: $table.at, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get summary =>
      $composableBuilder(column: $table.summary, builder: (column) => column);
}

class $$JobEventsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $JobEventsTable,
          JobEvent,
          $$JobEventsTableFilterComposer,
          $$JobEventsTableOrderingComposer,
          $$JobEventsTableAnnotationComposer,
          $$JobEventsTableCreateCompanionBuilder,
          $$JobEventsTableUpdateCompanionBuilder,
          (JobEvent, BaseReferences<_$AppDatabase, $JobEventsTable, JobEvent>),
          JobEvent,
          PrefetchHooks Function()
        > {
  $$JobEventsTableTableManager(_$AppDatabase db, $JobEventsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$JobEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$JobEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$JobEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> hlc = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<String> applicationId = const Value.absent(),
                Value<String> at = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> summary = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => JobEventsCompanion(
                id: id,
                hlc: hlc,
                deleted: deleted,
                applicationId: applicationId,
                at: at,
                kind: kind,
                summary: summary,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String> hlc = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                required String applicationId,
                required String at,
                required String kind,
                Value<String> summary = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => JobEventsCompanion.insert(
                id: id,
                hlc: hlc,
                deleted: deleted,
                applicationId: applicationId,
                at: at,
                kind: kind,
                summary: summary,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$JobEventsTable, JobEvent>(table),
                  BaseReferences<_$AppDatabase, $JobEventsTable, JobEvent>(
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

typedef $$JobEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $JobEventsTable,
      JobEvent,
      $$JobEventsTableFilterComposer,
      $$JobEventsTableOrderingComposer,
      $$JobEventsTableAnnotationComposer,
      $$JobEventsTableCreateCompanionBuilder,
      $$JobEventsTableUpdateCompanionBuilder,
      (JobEvent, BaseReferences<_$AppDatabase, $JobEventsTable, JobEvent>),
      JobEvent,
      PrefetchHooks Function()
    >;
typedef $$JobChecksTableCreateCompanionBuilder = JobChecksCompanion Function({
  required String id,
  Value<String> hlc,
  Value<bool> deleted,
  required String applicationId,
  required String kind,
  required String title,
  Value<String> status,
  Value<String?> due,
  Value<String?> done,
  Value<String> notes,
  Value<int> rowid,
});
typedef $$JobChecksTableUpdateCompanionBuilder = JobChecksCompanion Function({
  Value<String> id,
  Value<String> hlc,
  Value<bool> deleted,
  Value<String> applicationId,
  Value<String> kind,
  Value<String> title,
  Value<String> status,
  Value<String?> due,
  Value<String?> done,
  Value<String> notes,
  Value<int> rowid,
});

class $$JobChecksTableFilterComposer
    extends Composer<_$AppDatabase, $JobChecksTable> {
  $$JobChecksTableFilterComposer({
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

  ColumnFilters<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get applicationId => $composableBuilder(
    column: $table.applicationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get due => $composableBuilder(
    column: $table.due,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get done => $composableBuilder(
    column: $table.done,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );
}

class $$JobChecksTableOrderingComposer
    extends Composer<_$AppDatabase, $JobChecksTable> {
  $$JobChecksTableOrderingComposer({
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

  ColumnOrderings<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get applicationId => $composableBuilder(
    column: $table.applicationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get due => $composableBuilder(
    column: $table.due,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get done => $composableBuilder(
    column: $table.done,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$JobChecksTableAnnotationComposer
    extends Composer<_$AppDatabase, $JobChecksTable> {
  $$JobChecksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get hlc =>
      $composableBuilder(column: $table.hlc, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<String> get applicationId => $composableBuilder(
    column: $table.applicationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get due =>
      $composableBuilder(column: $table.due, builder: (column) => column);

  GeneratedColumn<String> get done =>
      $composableBuilder(column: $table.done, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);
}

class $$JobChecksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $JobChecksTable,
          JobCheck,
          $$JobChecksTableFilterComposer,
          $$JobChecksTableOrderingComposer,
          $$JobChecksTableAnnotationComposer,
          $$JobChecksTableCreateCompanionBuilder,
          $$JobChecksTableUpdateCompanionBuilder,
          (JobCheck, BaseReferences<_$AppDatabase, $JobChecksTable, JobCheck>),
          JobCheck,
          PrefetchHooks Function()
        > {
  $$JobChecksTableTableManager(_$AppDatabase db, $JobChecksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$JobChecksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$JobChecksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$JobChecksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> hlc = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<String> applicationId = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> due = const Value.absent(),
                Value<String?> done = const Value.absent(),
                Value<String> notes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => JobChecksCompanion(
                id: id,
                hlc: hlc,
                deleted: deleted,
                applicationId: applicationId,
                kind: kind,
                title: title,
                status: status,
                due: due,
                done: done,
                notes: notes,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String> hlc = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                required String applicationId,
                required String kind,
                required String title,
                Value<String> status = const Value.absent(),
                Value<String?> due = const Value.absent(),
                Value<String?> done = const Value.absent(),
                Value<String> notes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => JobChecksCompanion.insert(
                id: id,
                hlc: hlc,
                deleted: deleted,
                applicationId: applicationId,
                kind: kind,
                title: title,
                status: status,
                due: due,
                done: done,
                notes: notes,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$JobChecksTable, JobCheck>(table),
                  BaseReferences<_$AppDatabase, $JobChecksTable, JobCheck>(
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

typedef $$JobChecksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $JobChecksTable,
      JobCheck,
      $$JobChecksTableFilterComposer,
      $$JobChecksTableOrderingComposer,
      $$JobChecksTableAnnotationComposer,
      $$JobChecksTableCreateCompanionBuilder,
      $$JobChecksTableUpdateCompanionBuilder,
      (JobCheck, BaseReferences<_$AppDatabase, $JobChecksTable, JobCheck>),
      JobCheck,
      PrefetchHooks Function()
    >;
typedef $$JobArchiveTableCreateCompanionBuilder = JobArchiveCompanion Function({
  required String id,
  Value<String> hlc,
  Value<bool> deleted,
  Value<String?> applicationId,
  Value<String?> jobId,
  required String kind,
  required String at,
  Value<String> title,
  Value<String> url,
  required String content,
  Value<int> rowid,
});
typedef $$JobArchiveTableUpdateCompanionBuilder = JobArchiveCompanion Function({
  Value<String> id,
  Value<String> hlc,
  Value<bool> deleted,
  Value<String?> applicationId,
  Value<String?> jobId,
  Value<String> kind,
  Value<String> at,
  Value<String> title,
  Value<String> url,
  Value<String> content,
  Value<int> rowid,
});

class $$JobArchiveTableFilterComposer
    extends Composer<_$AppDatabase, $JobArchiveTable> {
  $$JobArchiveTableFilterComposer({
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

  ColumnFilters<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get applicationId => $composableBuilder(
    column: $table.applicationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get jobId => $composableBuilder(
    column: $table.jobId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );
}

class $$JobArchiveTableOrderingComposer
    extends Composer<_$AppDatabase, $JobArchiveTable> {
  $$JobArchiveTableOrderingComposer({
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

  ColumnOrderings<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get applicationId => $composableBuilder(
    column: $table.applicationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get jobId => $composableBuilder(
    column: $table.jobId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$JobArchiveTableAnnotationComposer
    extends Composer<_$AppDatabase, $JobArchiveTable> {
  $$JobArchiveTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get hlc =>
      $composableBuilder(column: $table.hlc, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<String> get applicationId => $composableBuilder(
    column: $table.applicationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get jobId =>
      $composableBuilder(column: $table.jobId, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get at =>
      $composableBuilder(column: $table.at, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);
}

class $$JobArchiveTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $JobArchiveTable,
          Archived,
          $$JobArchiveTableFilterComposer,
          $$JobArchiveTableOrderingComposer,
          $$JobArchiveTableAnnotationComposer,
          $$JobArchiveTableCreateCompanionBuilder,
          $$JobArchiveTableUpdateCompanionBuilder,
          (Archived, BaseReferences<_$AppDatabase, $JobArchiveTable, Archived>),
          Archived,
          PrefetchHooks Function()
        > {
  $$JobArchiveTableTableManager(_$AppDatabase db, $JobArchiveTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$JobArchiveTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$JobArchiveTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$JobArchiveTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> hlc = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<String?> applicationId = const Value.absent(),
                Value<String?> jobId = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> at = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> url = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => JobArchiveCompanion(
                id: id,
                hlc: hlc,
                deleted: deleted,
                applicationId: applicationId,
                jobId: jobId,
                kind: kind,
                at: at,
                title: title,
                url: url,
                content: content,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String> hlc = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<String?> applicationId = const Value.absent(),
                Value<String?> jobId = const Value.absent(),
                required String kind,
                required String at,
                Value<String> title = const Value.absent(),
                Value<String> url = const Value.absent(),
                required String content,
                Value<int> rowid = const Value.absent(),
              }) => JobArchiveCompanion.insert(
                id: id,
                hlc: hlc,
                deleted: deleted,
                applicationId: applicationId,
                jobId: jobId,
                kind: kind,
                at: at,
                title: title,
                url: url,
                content: content,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$JobArchiveTable, Archived>(table),
                  BaseReferences<_$AppDatabase, $JobArchiveTable, Archived>(
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

typedef $$JobArchiveTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $JobArchiveTable,
      Archived,
      $$JobArchiveTableFilterComposer,
      $$JobArchiveTableOrderingComposer,
      $$JobArchiveTableAnnotationComposer,
      $$JobArchiveTableCreateCompanionBuilder,
      $$JobArchiveTableUpdateCompanionBuilder,
      (Archived, BaseReferences<_$AppDatabase, $JobArchiveTable, Archived>),
      Archived,
      PrefetchHooks Function()
    >;
typedef $$CareerContactsTableCreateCompanionBuilder =
    CareerContactsCompanion Function({
      required String id,
      Value<String> hlc,
      Value<bool> deleted,
      required String name,
      Value<String> kind,
      Value<String> title,
      Value<String> company,
      Value<String> email,
      Value<String> phone,
      Value<String> linkedin,
      Value<String> source,
      Value<String> status,
      Value<String?> lastContact,
      Value<String?> followUp,
      Value<String?> jobId,
      Value<String> notes,
      Value<String> sourceUrl,
      Value<String> sourceKind,
      Value<String?> foundOn,
      Value<String> basis,
      Value<String> basisNote,
      Value<bool> doNotContact,
      Value<int?> keepInTouchWeeks,
      Value<int> rowid,
    });
typedef $$CareerContactsTableUpdateCompanionBuilder =
    CareerContactsCompanion Function({
      Value<String> id,
      Value<String> hlc,
      Value<bool> deleted,
      Value<String> name,
      Value<String> kind,
      Value<String> title,
      Value<String> company,
      Value<String> email,
      Value<String> phone,
      Value<String> linkedin,
      Value<String> source,
      Value<String> status,
      Value<String?> lastContact,
      Value<String?> followUp,
      Value<String?> jobId,
      Value<String> notes,
      Value<String> sourceUrl,
      Value<String> sourceKind,
      Value<String?> foundOn,
      Value<String> basis,
      Value<String> basisNote,
      Value<bool> doNotContact,
      Value<int?> keepInTouchWeeks,
      Value<int> rowid,
    });

class $$CareerContactsTableFilterComposer
    extends Composer<_$AppDatabase, $CareerContactsTable> {
  $$CareerContactsTableFilterComposer({
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

  ColumnFilters<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get company => $composableBuilder(
    column: $table.company,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get linkedin => $composableBuilder(
    column: $table.linkedin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastContact => $composableBuilder(
    column: $table.lastContact,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get followUp => $composableBuilder(
    column: $table.followUp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get jobId => $composableBuilder(
    column: $table.jobId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceUrl => $composableBuilder(
    column: $table.sourceUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceKind => $composableBuilder(
    column: $table.sourceKind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get foundOn => $composableBuilder(
    column: $table.foundOn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get basis => $composableBuilder(
    column: $table.basis,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get basisNote => $composableBuilder(
    column: $table.basisNote,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get doNotContact => $composableBuilder(
    column: $table.doNotContact,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get keepInTouchWeeks => $composableBuilder(
    column: $table.keepInTouchWeeks,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CareerContactsTableOrderingComposer
    extends Composer<_$AppDatabase, $CareerContactsTable> {
  $$CareerContactsTableOrderingComposer({
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

  ColumnOrderings<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get company => $composableBuilder(
    column: $table.company,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get linkedin => $composableBuilder(
    column: $table.linkedin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastContact => $composableBuilder(
    column: $table.lastContact,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get followUp => $composableBuilder(
    column: $table.followUp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get jobId => $composableBuilder(
    column: $table.jobId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceUrl => $composableBuilder(
    column: $table.sourceUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceKind => $composableBuilder(
    column: $table.sourceKind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get foundOn => $composableBuilder(
    column: $table.foundOn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get basis => $composableBuilder(
    column: $table.basis,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get basisNote => $composableBuilder(
    column: $table.basisNote,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get doNotContact => $composableBuilder(
    column: $table.doNotContact,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get keepInTouchWeeks => $composableBuilder(
    column: $table.keepInTouchWeeks,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CareerContactsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CareerContactsTable> {
  $$CareerContactsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get hlc =>
      $composableBuilder(column: $table.hlc, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get company =>
      $composableBuilder(column: $table.company, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<String> get linkedin =>
      $composableBuilder(column: $table.linkedin, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get lastContact => $composableBuilder(
    column: $table.lastContact,
    builder: (column) => column,
  );

  GeneratedColumn<String> get followUp =>
      $composableBuilder(column: $table.followUp, builder: (column) => column);

  GeneratedColumn<String> get jobId =>
      $composableBuilder(column: $table.jobId, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get sourceUrl =>
      $composableBuilder(column: $table.sourceUrl, builder: (column) => column);

  GeneratedColumn<String> get sourceKind => $composableBuilder(
    column: $table.sourceKind,
    builder: (column) => column,
  );

  GeneratedColumn<String> get foundOn =>
      $composableBuilder(column: $table.foundOn, builder: (column) => column);

  GeneratedColumn<String> get basis =>
      $composableBuilder(column: $table.basis, builder: (column) => column);

  GeneratedColumn<String> get basisNote =>
      $composableBuilder(column: $table.basisNote, builder: (column) => column);

  GeneratedColumn<bool> get doNotContact => $composableBuilder(
    column: $table.doNotContact,
    builder: (column) => column,
  );

  GeneratedColumn<int> get keepInTouchWeeks => $composableBuilder(
    column: $table.keepInTouchWeeks,
    builder: (column) => column,
  );
}

class $$CareerContactsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CareerContactsTable,
          Lead,
          $$CareerContactsTableFilterComposer,
          $$CareerContactsTableOrderingComposer,
          $$CareerContactsTableAnnotationComposer,
          $$CareerContactsTableCreateCompanionBuilder,
          $$CareerContactsTableUpdateCompanionBuilder,
          (Lead, BaseReferences<_$AppDatabase, $CareerContactsTable, Lead>),
          Lead,
          PrefetchHooks Function()
        > {
  $$CareerContactsTableTableManager(
    _$AppDatabase db,
    $CareerContactsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CareerContactsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CareerContactsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CareerContactsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> hlc = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> company = const Value.absent(),
                Value<String> email = const Value.absent(),
                Value<String> phone = const Value.absent(),
                Value<String> linkedin = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> lastContact = const Value.absent(),
                Value<String?> followUp = const Value.absent(),
                Value<String?> jobId = const Value.absent(),
                Value<String> notes = const Value.absent(),
                Value<String> sourceUrl = const Value.absent(),
                Value<String> sourceKind = const Value.absent(),
                Value<String?> foundOn = const Value.absent(),
                Value<String> basis = const Value.absent(),
                Value<String> basisNote = const Value.absent(),
                Value<bool> doNotContact = const Value.absent(),
                Value<int?> keepInTouchWeeks = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CareerContactsCompanion(
                id: id,
                hlc: hlc,
                deleted: deleted,
                name: name,
                kind: kind,
                title: title,
                company: company,
                email: email,
                phone: phone,
                linkedin: linkedin,
                source: source,
                status: status,
                lastContact: lastContact,
                followUp: followUp,
                jobId: jobId,
                notes: notes,
                sourceUrl: sourceUrl,
                sourceKind: sourceKind,
                foundOn: foundOn,
                basis: basis,
                basisNote: basisNote,
                doNotContact: doNotContact,
                keepInTouchWeeks: keepInTouchWeeks,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String> hlc = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                required String name,
                Value<String> kind = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> company = const Value.absent(),
                Value<String> email = const Value.absent(),
                Value<String> phone = const Value.absent(),
                Value<String> linkedin = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> lastContact = const Value.absent(),
                Value<String?> followUp = const Value.absent(),
                Value<String?> jobId = const Value.absent(),
                Value<String> notes = const Value.absent(),
                Value<String> sourceUrl = const Value.absent(),
                Value<String> sourceKind = const Value.absent(),
                Value<String?> foundOn = const Value.absent(),
                Value<String> basis = const Value.absent(),
                Value<String> basisNote = const Value.absent(),
                Value<bool> doNotContact = const Value.absent(),
                Value<int?> keepInTouchWeeks = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CareerContactsCompanion.insert(
                id: id,
                hlc: hlc,
                deleted: deleted,
                name: name,
                kind: kind,
                title: title,
                company: company,
                email: email,
                phone: phone,
                linkedin: linkedin,
                source: source,
                status: status,
                lastContact: lastContact,
                followUp: followUp,
                jobId: jobId,
                notes: notes,
                sourceUrl: sourceUrl,
                sourceKind: sourceKind,
                foundOn: foundOn,
                basis: basis,
                basisNote: basisNote,
                doNotContact: doNotContact,
                keepInTouchWeeks: keepInTouchWeeks,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CareerContactsTable, Lead>(table),
                  BaseReferences<_$AppDatabase, $CareerContactsTable, Lead>(
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

typedef $$CareerContactsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CareerContactsTable,
      Lead,
      $$CareerContactsTableFilterComposer,
      $$CareerContactsTableOrderingComposer,
      $$CareerContactsTableAnnotationComposer,
      $$CareerContactsTableCreateCompanionBuilder,
      $$CareerContactsTableUpdateCompanionBuilder,
      (Lead, BaseReferences<_$AppDatabase, $CareerContactsTable, Lead>),
      Lead,
      PrefetchHooks Function()
    >;
typedef $$CareerResumesTableCreateCompanionBuilder =
    CareerResumesCompanion Function({
      required String id,
      Value<String> hlc,
      Value<bool> deleted,
      required String name,
      Value<String?> jobId,
      required String created,
      required String content,
      Value<String> tailoring,
      Value<int> rowid,
    });
typedef $$CareerResumesTableUpdateCompanionBuilder =
    CareerResumesCompanion Function({
      Value<String> id,
      Value<String> hlc,
      Value<bool> deleted,
      Value<String> name,
      Value<String?> jobId,
      Value<String> created,
      Value<String> content,
      Value<String> tailoring,
      Value<int> rowid,
    });

class $$CareerResumesTableFilterComposer
    extends Composer<_$AppDatabase, $CareerResumesTable> {
  $$CareerResumesTableFilterComposer({
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

  ColumnFilters<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get jobId => $composableBuilder(
    column: $table.jobId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get created => $composableBuilder(
    column: $table.created,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tailoring => $composableBuilder(
    column: $table.tailoring,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CareerResumesTableOrderingComposer
    extends Composer<_$AppDatabase, $CareerResumesTable> {
  $$CareerResumesTableOrderingComposer({
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

  ColumnOrderings<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get jobId => $composableBuilder(
    column: $table.jobId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get created => $composableBuilder(
    column: $table.created,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tailoring => $composableBuilder(
    column: $table.tailoring,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CareerResumesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CareerResumesTable> {
  $$CareerResumesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get hlc =>
      $composableBuilder(column: $table.hlc, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get jobId =>
      $composableBuilder(column: $table.jobId, builder: (column) => column);

  GeneratedColumn<String> get created =>
      $composableBuilder(column: $table.created, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get tailoring =>
      $composableBuilder(column: $table.tailoring, builder: (column) => column);
}

class $$CareerResumesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CareerResumesTable,
          Resume,
          $$CareerResumesTableFilterComposer,
          $$CareerResumesTableOrderingComposer,
          $$CareerResumesTableAnnotationComposer,
          $$CareerResumesTableCreateCompanionBuilder,
          $$CareerResumesTableUpdateCompanionBuilder,
          (Resume, BaseReferences<_$AppDatabase, $CareerResumesTable, Resume>),
          Resume,
          PrefetchHooks Function()
        > {
  $$CareerResumesTableTableManager(_$AppDatabase db, $CareerResumesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CareerResumesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CareerResumesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CareerResumesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> hlc = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> jobId = const Value.absent(),
                Value<String> created = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<String> tailoring = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CareerResumesCompanion(
                id: id,
                hlc: hlc,
                deleted: deleted,
                name: name,
                jobId: jobId,
                created: created,
                content: content,
                tailoring: tailoring,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String> hlc = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                required String name,
                Value<String?> jobId = const Value.absent(),
                required String created,
                required String content,
                Value<String> tailoring = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CareerResumesCompanion.insert(
                id: id,
                hlc: hlc,
                deleted: deleted,
                name: name,
                jobId: jobId,
                created: created,
                content: content,
                tailoring: tailoring,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CareerResumesTable, Resume>(table),
                  BaseReferences<_$AppDatabase, $CareerResumesTable, Resume>(
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

typedef $$CareerResumesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CareerResumesTable,
      Resume,
      $$CareerResumesTableFilterComposer,
      $$CareerResumesTableOrderingComposer,
      $$CareerResumesTableAnnotationComposer,
      $$CareerResumesTableCreateCompanionBuilder,
      $$CareerResumesTableUpdateCompanionBuilder,
      (Resume, BaseReferences<_$AppDatabase, $CareerResumesTable, Resume>),
      Resume,
      PrefetchHooks Function()
    >;
typedef $$CareerReportsTableCreateCompanionBuilder =
    CareerReportsCompanion Function({
      required String id,
      Value<String> hlc,
      Value<bool> deleted,
      required String kind,
      required String created,
      required String content,
      Value<String> sources,
      Value<int> rowid,
    });
typedef $$CareerReportsTableUpdateCompanionBuilder =
    CareerReportsCompanion Function({
      Value<String> id,
      Value<String> hlc,
      Value<bool> deleted,
      Value<String> kind,
      Value<String> created,
      Value<String> content,
      Value<String> sources,
      Value<int> rowid,
    });

class $$CareerReportsTableFilterComposer
    extends Composer<_$AppDatabase, $CareerReportsTable> {
  $$CareerReportsTableFilterComposer({
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

  ColumnFilters<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get created => $composableBuilder(
    column: $table.created,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sources => $composableBuilder(
    column: $table.sources,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CareerReportsTableOrderingComposer
    extends Composer<_$AppDatabase, $CareerReportsTable> {
  $$CareerReportsTableOrderingComposer({
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

  ColumnOrderings<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get created => $composableBuilder(
    column: $table.created,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sources => $composableBuilder(
    column: $table.sources,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CareerReportsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CareerReportsTable> {
  $$CareerReportsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get hlc =>
      $composableBuilder(column: $table.hlc, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get created =>
      $composableBuilder(column: $table.created, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get sources =>
      $composableBuilder(column: $table.sources, builder: (column) => column);
}

class $$CareerReportsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CareerReportsTable,
          Report,
          $$CareerReportsTableFilterComposer,
          $$CareerReportsTableOrderingComposer,
          $$CareerReportsTableAnnotationComposer,
          $$CareerReportsTableCreateCompanionBuilder,
          $$CareerReportsTableUpdateCompanionBuilder,
          (Report, BaseReferences<_$AppDatabase, $CareerReportsTable, Report>),
          Report,
          PrefetchHooks Function()
        > {
  $$CareerReportsTableTableManager(_$AppDatabase db, $CareerReportsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CareerReportsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CareerReportsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CareerReportsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> hlc = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> created = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<String> sources = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CareerReportsCompanion(
                id: id,
                hlc: hlc,
                deleted: deleted,
                kind: kind,
                created: created,
                content: content,
                sources: sources,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String> hlc = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                required String kind,
                required String created,
                required String content,
                Value<String> sources = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CareerReportsCompanion.insert(
                id: id,
                hlc: hlc,
                deleted: deleted,
                kind: kind,
                created: created,
                content: content,
                sources: sources,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CareerReportsTable, Report>(table),
                  BaseReferences<_$AppDatabase, $CareerReportsTable, Report>(
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

typedef $$CareerReportsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CareerReportsTable,
      Report,
      $$CareerReportsTableFilterComposer,
      $$CareerReportsTableOrderingComposer,
      $$CareerReportsTableAnnotationComposer,
      $$CareerReportsTableCreateCompanionBuilder,
      $$CareerReportsTableUpdateCompanionBuilder,
      (Report, BaseReferences<_$AppDatabase, $CareerReportsTable, Report>),
      Report,
      PrefetchHooks Function()
    >;
typedef $$CareerGrowthTableCreateCompanionBuilder =
    CareerGrowthCompanion Function({
      required String id,
      Value<String> hlc,
      Value<bool> deleted,
      required String title,
      required String kind,
      Value<String> provider,
      Value<String> url,
      Value<String> why,
      Value<String> cost,
      Value<String> duration,
      Value<String> status,
      Value<int> progress,
      Value<String?> target,
      Value<String?> done,
      Value<String> path,
      required String added,
      Value<int> rowid,
    });
typedef $$CareerGrowthTableUpdateCompanionBuilder =
    CareerGrowthCompanion Function({
      Value<String> id,
      Value<String> hlc,
      Value<bool> deleted,
      Value<String> title,
      Value<String> kind,
      Value<String> provider,
      Value<String> url,
      Value<String> why,
      Value<String> cost,
      Value<String> duration,
      Value<String> status,
      Value<int> progress,
      Value<String?> target,
      Value<String?> done,
      Value<String> path,
      Value<String> added,
      Value<int> rowid,
    });

class $$CareerGrowthTableFilterComposer
    extends Composer<_$AppDatabase, $CareerGrowthTable> {
  $$CareerGrowthTableFilterComposer({
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

  ColumnFilters<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get provider => $composableBuilder(
    column: $table.provider,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get why => $composableBuilder(
    column: $table.why,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cost => $composableBuilder(
    column: $table.cost,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get duration => $composableBuilder(
    column: $table.duration,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get progress => $composableBuilder(
    column: $table.progress,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get target => $composableBuilder(
    column: $table.target,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get done => $composableBuilder(
    column: $table.done,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get added => $composableBuilder(
    column: $table.added,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CareerGrowthTableOrderingComposer
    extends Composer<_$AppDatabase, $CareerGrowthTable> {
  $$CareerGrowthTableOrderingComposer({
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

  ColumnOrderings<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get provider => $composableBuilder(
    column: $table.provider,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get why => $composableBuilder(
    column: $table.why,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cost => $composableBuilder(
    column: $table.cost,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get duration => $composableBuilder(
    column: $table.duration,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get progress => $composableBuilder(
    column: $table.progress,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get target => $composableBuilder(
    column: $table.target,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get done => $composableBuilder(
    column: $table.done,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get added => $composableBuilder(
    column: $table.added,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CareerGrowthTableAnnotationComposer
    extends Composer<_$AppDatabase, $CareerGrowthTable> {
  $$CareerGrowthTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get hlc =>
      $composableBuilder(column: $table.hlc, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get provider =>
      $composableBuilder(column: $table.provider, builder: (column) => column);

  GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  GeneratedColumn<String> get why =>
      $composableBuilder(column: $table.why, builder: (column) => column);

  GeneratedColumn<String> get cost =>
      $composableBuilder(column: $table.cost, builder: (column) => column);

  GeneratedColumn<String> get duration =>
      $composableBuilder(column: $table.duration, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get progress =>
      $composableBuilder(column: $table.progress, builder: (column) => column);

  GeneratedColumn<String> get target =>
      $composableBuilder(column: $table.target, builder: (column) => column);

  GeneratedColumn<String> get done =>
      $composableBuilder(column: $table.done, builder: (column) => column);

  GeneratedColumn<String> get path =>
      $composableBuilder(column: $table.path, builder: (column) => column);

  GeneratedColumn<String> get added =>
      $composableBuilder(column: $table.added, builder: (column) => column);
}

class $$CareerGrowthTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CareerGrowthTable,
          GrowthItem,
          $$CareerGrowthTableFilterComposer,
          $$CareerGrowthTableOrderingComposer,
          $$CareerGrowthTableAnnotationComposer,
          $$CareerGrowthTableCreateCompanionBuilder,
          $$CareerGrowthTableUpdateCompanionBuilder,
          (
            GrowthItem,
            BaseReferences<_$AppDatabase, $CareerGrowthTable, GrowthItem>,
          ),
          GrowthItem,
          PrefetchHooks Function()
        > {
  $$CareerGrowthTableTableManager(_$AppDatabase db, $CareerGrowthTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CareerGrowthTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CareerGrowthTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CareerGrowthTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> hlc = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> provider = const Value.absent(),
                Value<String> url = const Value.absent(),
                Value<String> why = const Value.absent(),
                Value<String> cost = const Value.absent(),
                Value<String> duration = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> progress = const Value.absent(),
                Value<String?> target = const Value.absent(),
                Value<String?> done = const Value.absent(),
                Value<String> path = const Value.absent(),
                Value<String> added = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CareerGrowthCompanion(
                id: id,
                hlc: hlc,
                deleted: deleted,
                title: title,
                kind: kind,
                provider: provider,
                url: url,
                why: why,
                cost: cost,
                duration: duration,
                status: status,
                progress: progress,
                target: target,
                done: done,
                path: path,
                added: added,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String> hlc = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                required String title,
                required String kind,
                Value<String> provider = const Value.absent(),
                Value<String> url = const Value.absent(),
                Value<String> why = const Value.absent(),
                Value<String> cost = const Value.absent(),
                Value<String> duration = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> progress = const Value.absent(),
                Value<String?> target = const Value.absent(),
                Value<String?> done = const Value.absent(),
                Value<String> path = const Value.absent(),
                required String added,
                Value<int> rowid = const Value.absent(),
              }) => CareerGrowthCompanion.insert(
                id: id,
                hlc: hlc,
                deleted: deleted,
                title: title,
                kind: kind,
                provider: provider,
                url: url,
                why: why,
                cost: cost,
                duration: duration,
                status: status,
                progress: progress,
                target: target,
                done: done,
                path: path,
                added: added,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CareerGrowthTable, GrowthItem>(table),
                  BaseReferences<_$AppDatabase, $CareerGrowthTable, GrowthItem>(
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

typedef $$CareerGrowthTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CareerGrowthTable,
      GrowthItem,
      $$CareerGrowthTableFilterComposer,
      $$CareerGrowthTableOrderingComposer,
      $$CareerGrowthTableAnnotationComposer,
      $$CareerGrowthTableCreateCompanionBuilder,
      $$CareerGrowthTableUpdateCompanionBuilder,
      (
        GrowthItem,
        BaseReferences<_$AppDatabase, $CareerGrowthTable, GrowthItem>,
      ),
      GrowthItem,
      PrefetchHooks Function()
    >;
typedef $$CareerPracticeTableCreateCompanionBuilder =
    CareerPracticeCompanion Function({
      required String id,
      Value<String> hlc,
      Value<bool> deleted,
      Value<String?> jobId,
      required String role,
      required String mode,
      required String started,
      required String questions,
      Value<double?> score,
      Value<String?> profileId,
      Value<String> debrief,
      Value<int?> nervesBefore,
      Value<int?> nervesAfter,
      Value<int> rowid,
    });
typedef $$CareerPracticeTableUpdateCompanionBuilder =
    CareerPracticeCompanion Function({
      Value<String> id,
      Value<String> hlc,
      Value<bool> deleted,
      Value<String?> jobId,
      Value<String> role,
      Value<String> mode,
      Value<String> started,
      Value<String> questions,
      Value<double?> score,
      Value<String?> profileId,
      Value<String> debrief,
      Value<int?> nervesBefore,
      Value<int?> nervesAfter,
      Value<int> rowid,
    });

class $$CareerPracticeTableFilterComposer
    extends Composer<_$AppDatabase, $CareerPracticeTable> {
  $$CareerPracticeTableFilterComposer({
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

  ColumnFilters<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get jobId => $composableBuilder(
    column: $table.jobId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get started => $composableBuilder(
    column: $table.started,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get questions => $composableBuilder(
    column: $table.questions,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get profileId => $composableBuilder(
    column: $table.profileId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get debrief => $composableBuilder(
    column: $table.debrief,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get nervesBefore => $composableBuilder(
    column: $table.nervesBefore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get nervesAfter => $composableBuilder(
    column: $table.nervesAfter,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CareerPracticeTableOrderingComposer
    extends Composer<_$AppDatabase, $CareerPracticeTable> {
  $$CareerPracticeTableOrderingComposer({
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

  ColumnOrderings<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get jobId => $composableBuilder(
    column: $table.jobId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get started => $composableBuilder(
    column: $table.started,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get questions => $composableBuilder(
    column: $table.questions,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get profileId => $composableBuilder(
    column: $table.profileId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get debrief => $composableBuilder(
    column: $table.debrief,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get nervesBefore => $composableBuilder(
    column: $table.nervesBefore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get nervesAfter => $composableBuilder(
    column: $table.nervesAfter,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CareerPracticeTableAnnotationComposer
    extends Composer<_$AppDatabase, $CareerPracticeTable> {
  $$CareerPracticeTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get hlc =>
      $composableBuilder(column: $table.hlc, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<String> get jobId =>
      $composableBuilder(column: $table.jobId, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get mode =>
      $composableBuilder(column: $table.mode, builder: (column) => column);

  GeneratedColumn<String> get started =>
      $composableBuilder(column: $table.started, builder: (column) => column);

  GeneratedColumn<String> get questions =>
      $composableBuilder(column: $table.questions, builder: (column) => column);

  GeneratedColumn<double> get score =>
      $composableBuilder(column: $table.score, builder: (column) => column);

  GeneratedColumn<String> get profileId =>
      $composableBuilder(column: $table.profileId, builder: (column) => column);

  GeneratedColumn<String> get debrief =>
      $composableBuilder(column: $table.debrief, builder: (column) => column);

  GeneratedColumn<int> get nervesBefore => $composableBuilder(
    column: $table.nervesBefore,
    builder: (column) => column,
  );

  GeneratedColumn<int> get nervesAfter => $composableBuilder(
    column: $table.nervesAfter,
    builder: (column) => column,
  );
}

class $$CareerPracticeTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CareerPracticeTable,
          PracticeSession,
          $$CareerPracticeTableFilterComposer,
          $$CareerPracticeTableOrderingComposer,
          $$CareerPracticeTableAnnotationComposer,
          $$CareerPracticeTableCreateCompanionBuilder,
          $$CareerPracticeTableUpdateCompanionBuilder,
          (
            PracticeSession,
            BaseReferences<
              _$AppDatabase,
              $CareerPracticeTable,
              PracticeSession
            >,
          ),
          PracticeSession,
          PrefetchHooks Function()
        > {
  $$CareerPracticeTableTableManager(
    _$AppDatabase db,
    $CareerPracticeTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CareerPracticeTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CareerPracticeTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CareerPracticeTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> hlc = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<String?> jobId = const Value.absent(),
                Value<String> role = const Value.absent(),
                Value<String> mode = const Value.absent(),
                Value<String> started = const Value.absent(),
                Value<String> questions = const Value.absent(),
                Value<double?> score = const Value.absent(),
                Value<String?> profileId = const Value.absent(),
                Value<String> debrief = const Value.absent(),
                Value<int?> nervesBefore = const Value.absent(),
                Value<int?> nervesAfter = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CareerPracticeCompanion(
                id: id,
                hlc: hlc,
                deleted: deleted,
                jobId: jobId,
                role: role,
                mode: mode,
                started: started,
                questions: questions,
                score: score,
                profileId: profileId,
                debrief: debrief,
                nervesBefore: nervesBefore,
                nervesAfter: nervesAfter,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String> hlc = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<String?> jobId = const Value.absent(),
                required String role,
                required String mode,
                required String started,
                required String questions,
                Value<double?> score = const Value.absent(),
                Value<String?> profileId = const Value.absent(),
                Value<String> debrief = const Value.absent(),
                Value<int?> nervesBefore = const Value.absent(),
                Value<int?> nervesAfter = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CareerPracticeCompanion.insert(
                id: id,
                hlc: hlc,
                deleted: deleted,
                jobId: jobId,
                role: role,
                mode: mode,
                started: started,
                questions: questions,
                score: score,
                profileId: profileId,
                debrief: debrief,
                nervesBefore: nervesBefore,
                nervesAfter: nervesAfter,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CareerPracticeTable, PracticeSession>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $CareerPracticeTable,
                    PracticeSession
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CareerPracticeTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CareerPracticeTable,
      PracticeSession,
      $$CareerPracticeTableFilterComposer,
      $$CareerPracticeTableOrderingComposer,
      $$CareerPracticeTableAnnotationComposer,
      $$CareerPracticeTableCreateCompanionBuilder,
      $$CareerPracticeTableUpdateCompanionBuilder,
      (
        PracticeSession,
        BaseReferences<_$AppDatabase, $CareerPracticeTable, PracticeSession>,
      ),
      PracticeSession,
      PrefetchHooks Function()
    >;
typedef $$CareerAnswersTableCreateCompanionBuilder =
    CareerAnswersCompanion Function({
      required String id,
      Value<String> hlc,
      Value<bool> deleted,
      required String sessionId,
      required int question,
      required String answer,
      required String at,
      Value<String> review,
      Value<double?> score,
      Value<int> rowid,
    });
typedef $$CareerAnswersTableUpdateCompanionBuilder =
    CareerAnswersCompanion Function({
      Value<String> id,
      Value<String> hlc,
      Value<bool> deleted,
      Value<String> sessionId,
      Value<int> question,
      Value<String> answer,
      Value<String> at,
      Value<String> review,
      Value<double?> score,
      Value<int> rowid,
    });

class $$CareerAnswersTableFilterComposer
    extends Composer<_$AppDatabase, $CareerAnswersTable> {
  $$CareerAnswersTableFilterComposer({
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

  ColumnFilters<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get question => $composableBuilder(
    column: $table.question,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get answer => $composableBuilder(
    column: $table.answer,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get review => $composableBuilder(
    column: $table.review,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CareerAnswersTableOrderingComposer
    extends Composer<_$AppDatabase, $CareerAnswersTable> {
  $$CareerAnswersTableOrderingComposer({
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

  ColumnOrderings<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get question => $composableBuilder(
    column: $table.question,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get answer => $composableBuilder(
    column: $table.answer,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get review => $composableBuilder(
    column: $table.review,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CareerAnswersTableAnnotationComposer
    extends Composer<_$AppDatabase, $CareerAnswersTable> {
  $$CareerAnswersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get hlc =>
      $composableBuilder(column: $table.hlc, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<String> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumn<int> get question =>
      $composableBuilder(column: $table.question, builder: (column) => column);

  GeneratedColumn<String> get answer =>
      $composableBuilder(column: $table.answer, builder: (column) => column);

  GeneratedColumn<String> get at =>
      $composableBuilder(column: $table.at, builder: (column) => column);

  GeneratedColumn<String> get review =>
      $composableBuilder(column: $table.review, builder: (column) => column);

  GeneratedColumn<double> get score =>
      $composableBuilder(column: $table.score, builder: (column) => column);
}

class $$CareerAnswersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CareerAnswersTable,
          PracticeAnswer,
          $$CareerAnswersTableFilterComposer,
          $$CareerAnswersTableOrderingComposer,
          $$CareerAnswersTableAnnotationComposer,
          $$CareerAnswersTableCreateCompanionBuilder,
          $$CareerAnswersTableUpdateCompanionBuilder,
          (
            PracticeAnswer,
            BaseReferences<_$AppDatabase, $CareerAnswersTable, PracticeAnswer>,
          ),
          PracticeAnswer,
          PrefetchHooks Function()
        > {
  $$CareerAnswersTableTableManager(_$AppDatabase db, $CareerAnswersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CareerAnswersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CareerAnswersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CareerAnswersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> hlc = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<String> sessionId = const Value.absent(),
                Value<int> question = const Value.absent(),
                Value<String> answer = const Value.absent(),
                Value<String> at = const Value.absent(),
                Value<String> review = const Value.absent(),
                Value<double?> score = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CareerAnswersCompanion(
                id: id,
                hlc: hlc,
                deleted: deleted,
                sessionId: sessionId,
                question: question,
                answer: answer,
                at: at,
                review: review,
                score: score,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String> hlc = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                required String sessionId,
                required int question,
                required String answer,
                required String at,
                Value<String> review = const Value.absent(),
                Value<double?> score = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CareerAnswersCompanion.insert(
                id: id,
                hlc: hlc,
                deleted: deleted,
                sessionId: sessionId,
                question: question,
                answer: answer,
                at: at,
                review: review,
                score: score,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CareerAnswersTable, PracticeAnswer>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $CareerAnswersTable,
                    PracticeAnswer
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CareerAnswersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CareerAnswersTable,
      PracticeAnswer,
      $$CareerAnswersTableFilterComposer,
      $$CareerAnswersTableOrderingComposer,
      $$CareerAnswersTableAnnotationComposer,
      $$CareerAnswersTableCreateCompanionBuilder,
      $$CareerAnswersTableUpdateCompanionBuilder,
      (
        PracticeAnswer,
        BaseReferences<_$AppDatabase, $CareerAnswersTable, PracticeAnswer>,
      ),
      PracticeAnswer,
      PrefetchHooks Function()
    >;
typedef $$CareerDocumentsTableCreateCompanionBuilder =
    CareerDocumentsCompanion Function({
      required String id,
      Value<String> hlc,
      Value<bool> deleted,
      required String hash,
      required String name,
      Value<String> kind,
      Value<String> summary,
      Value<String> facts,
      Value<String> content,
      required String found,
      Value<String?> analysed,
      Value<bool> use,
      Value<int> rowid,
    });
typedef $$CareerDocumentsTableUpdateCompanionBuilder =
    CareerDocumentsCompanion Function({
      Value<String> id,
      Value<String> hlc,
      Value<bool> deleted,
      Value<String> hash,
      Value<String> name,
      Value<String> kind,
      Value<String> summary,
      Value<String> facts,
      Value<String> content,
      Value<String> found,
      Value<String?> analysed,
      Value<bool> use,
      Value<int> rowid,
    });

class $$CareerDocumentsTableFilterComposer
    extends Composer<_$AppDatabase, $CareerDocumentsTable> {
  $$CareerDocumentsTableFilterComposer({
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

  ColumnFilters<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hash => $composableBuilder(
    column: $table.hash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get summary => $composableBuilder(
    column: $table.summary,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get facts => $composableBuilder(
    column: $table.facts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get found => $composableBuilder(
    column: $table.found,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get analysed => $composableBuilder(
    column: $table.analysed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get use => $composableBuilder(
    column: $table.use,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CareerDocumentsTableOrderingComposer
    extends Composer<_$AppDatabase, $CareerDocumentsTable> {
  $$CareerDocumentsTableOrderingComposer({
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

  ColumnOrderings<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hash => $composableBuilder(
    column: $table.hash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get summary => $composableBuilder(
    column: $table.summary,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get facts => $composableBuilder(
    column: $table.facts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get found => $composableBuilder(
    column: $table.found,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get analysed => $composableBuilder(
    column: $table.analysed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get use => $composableBuilder(
    column: $table.use,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CareerDocumentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CareerDocumentsTable> {
  $$CareerDocumentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get hlc =>
      $composableBuilder(column: $table.hlc, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<String> get hash =>
      $composableBuilder(column: $table.hash, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get summary =>
      $composableBuilder(column: $table.summary, builder: (column) => column);

  GeneratedColumn<String> get facts =>
      $composableBuilder(column: $table.facts, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get found =>
      $composableBuilder(column: $table.found, builder: (column) => column);

  GeneratedColumn<String> get analysed =>
      $composableBuilder(column: $table.analysed, builder: (column) => column);

  GeneratedColumn<bool> get use =>
      $composableBuilder(column: $table.use, builder: (column) => column);
}

class $$CareerDocumentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CareerDocumentsTable,
          CareerDocument,
          $$CareerDocumentsTableFilterComposer,
          $$CareerDocumentsTableOrderingComposer,
          $$CareerDocumentsTableAnnotationComposer,
          $$CareerDocumentsTableCreateCompanionBuilder,
          $$CareerDocumentsTableUpdateCompanionBuilder,
          (
            CareerDocument,
            BaseReferences<
              _$AppDatabase,
              $CareerDocumentsTable,
              CareerDocument
            >,
          ),
          CareerDocument,
          PrefetchHooks Function()
        > {
  $$CareerDocumentsTableTableManager(
    _$AppDatabase db,
    $CareerDocumentsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CareerDocumentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CareerDocumentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CareerDocumentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> hlc = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<String> hash = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> summary = const Value.absent(),
                Value<String> facts = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<String> found = const Value.absent(),
                Value<String?> analysed = const Value.absent(),
                Value<bool> use = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CareerDocumentsCompanion(
                id: id,
                hlc: hlc,
                deleted: deleted,
                hash: hash,
                name: name,
                kind: kind,
                summary: summary,
                facts: facts,
                content: content,
                found: found,
                analysed: analysed,
                use: use,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String> hlc = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                required String hash,
                required String name,
                Value<String> kind = const Value.absent(),
                Value<String> summary = const Value.absent(),
                Value<String> facts = const Value.absent(),
                Value<String> content = const Value.absent(),
                required String found,
                Value<String?> analysed = const Value.absent(),
                Value<bool> use = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CareerDocumentsCompanion.insert(
                id: id,
                hlc: hlc,
                deleted: deleted,
                hash: hash,
                name: name,
                kind: kind,
                summary: summary,
                facts: facts,
                content: content,
                found: found,
                analysed: analysed,
                use: use,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CareerDocumentsTable, CareerDocument>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $CareerDocumentsTable,
                    CareerDocument
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CareerDocumentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CareerDocumentsTable,
      CareerDocument,
      $$CareerDocumentsTableFilterComposer,
      $$CareerDocumentsTableOrderingComposer,
      $$CareerDocumentsTableAnnotationComposer,
      $$CareerDocumentsTableCreateCompanionBuilder,
      $$CareerDocumentsTableUpdateCompanionBuilder,
      (
        CareerDocument,
        BaseReferences<_$AppDatabase, $CareerDocumentsTable, CareerDocument>,
      ),
      CareerDocument,
      PrefetchHooks Function()
    >;
typedef $$CareerQuestionsTableCreateCompanionBuilder =
    CareerQuestionsCompanion Function({
      required String id,
      Value<String> hlc,
      Value<bool> deleted,
      required String topic,
      required String question,
      Value<String> why,
      Value<String> choices,
      Value<String> status,
      Value<String> answer,
      required String asked,
      Value<String?> answered,
      Value<bool> applied,
      Value<int> rowid,
    });
typedef $$CareerQuestionsTableUpdateCompanionBuilder =
    CareerQuestionsCompanion Function({
      Value<String> id,
      Value<String> hlc,
      Value<bool> deleted,
      Value<String> topic,
      Value<String> question,
      Value<String> why,
      Value<String> choices,
      Value<String> status,
      Value<String> answer,
      Value<String> asked,
      Value<String?> answered,
      Value<bool> applied,
      Value<int> rowid,
    });

class $$CareerQuestionsTableFilterComposer
    extends Composer<_$AppDatabase, $CareerQuestionsTable> {
  $$CareerQuestionsTableFilterComposer({
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

  ColumnFilters<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get topic => $composableBuilder(
    column: $table.topic,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get question => $composableBuilder(
    column: $table.question,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get why => $composableBuilder(
    column: $table.why,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get choices => $composableBuilder(
    column: $table.choices,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get answer => $composableBuilder(
    column: $table.answer,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get asked => $composableBuilder(
    column: $table.asked,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get answered => $composableBuilder(
    column: $table.answered,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get applied => $composableBuilder(
    column: $table.applied,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CareerQuestionsTableOrderingComposer
    extends Composer<_$AppDatabase, $CareerQuestionsTable> {
  $$CareerQuestionsTableOrderingComposer({
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

  ColumnOrderings<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get topic => $composableBuilder(
    column: $table.topic,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get question => $composableBuilder(
    column: $table.question,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get why => $composableBuilder(
    column: $table.why,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get choices => $composableBuilder(
    column: $table.choices,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get answer => $composableBuilder(
    column: $table.answer,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get asked => $composableBuilder(
    column: $table.asked,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get answered => $composableBuilder(
    column: $table.answered,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get applied => $composableBuilder(
    column: $table.applied,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CareerQuestionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CareerQuestionsTable> {
  $$CareerQuestionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get hlc =>
      $composableBuilder(column: $table.hlc, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<String> get topic =>
      $composableBuilder(column: $table.topic, builder: (column) => column);

  GeneratedColumn<String> get question =>
      $composableBuilder(column: $table.question, builder: (column) => column);

  GeneratedColumn<String> get why =>
      $composableBuilder(column: $table.why, builder: (column) => column);

  GeneratedColumn<String> get choices =>
      $composableBuilder(column: $table.choices, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get answer =>
      $composableBuilder(column: $table.answer, builder: (column) => column);

  GeneratedColumn<String> get asked =>
      $composableBuilder(column: $table.asked, builder: (column) => column);

  GeneratedColumn<String> get answered =>
      $composableBuilder(column: $table.answered, builder: (column) => column);

  GeneratedColumn<bool> get applied =>
      $composableBuilder(column: $table.applied, builder: (column) => column);
}

class $$CareerQuestionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CareerQuestionsTable,
          ProfileQuestion,
          $$CareerQuestionsTableFilterComposer,
          $$CareerQuestionsTableOrderingComposer,
          $$CareerQuestionsTableAnnotationComposer,
          $$CareerQuestionsTableCreateCompanionBuilder,
          $$CareerQuestionsTableUpdateCompanionBuilder,
          (
            ProfileQuestion,
            BaseReferences<
              _$AppDatabase,
              $CareerQuestionsTable,
              ProfileQuestion
            >,
          ),
          ProfileQuestion,
          PrefetchHooks Function()
        > {
  $$CareerQuestionsTableTableManager(
    _$AppDatabase db,
    $CareerQuestionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CareerQuestionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CareerQuestionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CareerQuestionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> hlc = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<String> topic = const Value.absent(),
                Value<String> question = const Value.absent(),
                Value<String> why = const Value.absent(),
                Value<String> choices = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> answer = const Value.absent(),
                Value<String> asked = const Value.absent(),
                Value<String?> answered = const Value.absent(),
                Value<bool> applied = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CareerQuestionsCompanion(
                id: id,
                hlc: hlc,
                deleted: deleted,
                topic: topic,
                question: question,
                why: why,
                choices: choices,
                status: status,
                answer: answer,
                asked: asked,
                answered: answered,
                applied: applied,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String> hlc = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                required String topic,
                required String question,
                Value<String> why = const Value.absent(),
                Value<String> choices = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> answer = const Value.absent(),
                required String asked,
                Value<String?> answered = const Value.absent(),
                Value<bool> applied = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CareerQuestionsCompanion.insert(
                id: id,
                hlc: hlc,
                deleted: deleted,
                topic: topic,
                question: question,
                why: why,
                choices: choices,
                status: status,
                answer: answer,
                asked: asked,
                answered: answered,
                applied: applied,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CareerQuestionsTable, ProfileQuestion>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $CareerQuestionsTable,
                    ProfileQuestion
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CareerQuestionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CareerQuestionsTable,
      ProfileQuestion,
      $$CareerQuestionsTableFilterComposer,
      $$CareerQuestionsTableOrderingComposer,
      $$CareerQuestionsTableAnnotationComposer,
      $$CareerQuestionsTableCreateCompanionBuilder,
      $$CareerQuestionsTableUpdateCompanionBuilder,
      (
        ProfileQuestion,
        BaseReferences<_$AppDatabase, $CareerQuestionsTable, ProfileQuestion>,
      ),
      ProfileQuestion,
      PrefetchHooks Function()
    >;
typedef $$CareerJournalTableCreateCompanionBuilder =
    CareerJournalCompanion Function({
      required String id,
      Value<String> hlc,
      Value<bool> deleted,
      required String day,
      required String prompt,
      Value<String> entry,
      Value<String> digest,
      required String at,
      Value<int> rowid,
    });
typedef $$CareerJournalTableUpdateCompanionBuilder =
    CareerJournalCompanion Function({
      Value<String> id,
      Value<String> hlc,
      Value<bool> deleted,
      Value<String> day,
      Value<String> prompt,
      Value<String> entry,
      Value<String> digest,
      Value<String> at,
      Value<int> rowid,
    });

class $$CareerJournalTableFilterComposer
    extends Composer<_$AppDatabase, $CareerJournalTable> {
  $$CareerJournalTableFilterComposer({
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

  ColumnFilters<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get prompt => $composableBuilder(
    column: $table.prompt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entry => $composableBuilder(
    column: $table.entry,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get digest => $composableBuilder(
    column: $table.digest,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CareerJournalTableOrderingComposer
    extends Composer<_$AppDatabase, $CareerJournalTable> {
  $$CareerJournalTableOrderingComposer({
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

  ColumnOrderings<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get prompt => $composableBuilder(
    column: $table.prompt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entry => $composableBuilder(
    column: $table.entry,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get digest => $composableBuilder(
    column: $table.digest,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CareerJournalTableAnnotationComposer
    extends Composer<_$AppDatabase, $CareerJournalTable> {
  $$CareerJournalTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get hlc =>
      $composableBuilder(column: $table.hlc, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<String> get day =>
      $composableBuilder(column: $table.day, builder: (column) => column);

  GeneratedColumn<String> get prompt =>
      $composableBuilder(column: $table.prompt, builder: (column) => column);

  GeneratedColumn<String> get entry =>
      $composableBuilder(column: $table.entry, builder: (column) => column);

  GeneratedColumn<String> get digest =>
      $composableBuilder(column: $table.digest, builder: (column) => column);

  GeneratedColumn<String> get at =>
      $composableBuilder(column: $table.at, builder: (column) => column);
}

class $$CareerJournalTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CareerJournalTable,
          CheckIn,
          $$CareerJournalTableFilterComposer,
          $$CareerJournalTableOrderingComposer,
          $$CareerJournalTableAnnotationComposer,
          $$CareerJournalTableCreateCompanionBuilder,
          $$CareerJournalTableUpdateCompanionBuilder,
          (
            CheckIn,
            BaseReferences<_$AppDatabase, $CareerJournalTable, CheckIn>,
          ),
          CheckIn,
          PrefetchHooks Function()
        > {
  $$CareerJournalTableTableManager(_$AppDatabase db, $CareerJournalTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CareerJournalTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CareerJournalTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CareerJournalTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> hlc = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<String> day = const Value.absent(),
                Value<String> prompt = const Value.absent(),
                Value<String> entry = const Value.absent(),
                Value<String> digest = const Value.absent(),
                Value<String> at = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CareerJournalCompanion(
                id: id,
                hlc: hlc,
                deleted: deleted,
                day: day,
                prompt: prompt,
                entry: entry,
                digest: digest,
                at: at,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String> hlc = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                required String day,
                required String prompt,
                Value<String> entry = const Value.absent(),
                Value<String> digest = const Value.absent(),
                required String at,
                Value<int> rowid = const Value.absent(),
              }) => CareerJournalCompanion.insert(
                id: id,
                hlc: hlc,
                deleted: deleted,
                day: day,
                prompt: prompt,
                entry: entry,
                digest: digest,
                at: at,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CareerJournalTable, CheckIn>(table),
                  BaseReferences<_$AppDatabase, $CareerJournalTable, CheckIn>(
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

typedef $$CareerJournalTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CareerJournalTable,
      CheckIn,
      $$CareerJournalTableFilterComposer,
      $$CareerJournalTableOrderingComposer,
      $$CareerJournalTableAnnotationComposer,
      $$CareerJournalTableCreateCompanionBuilder,
      $$CareerJournalTableUpdateCompanionBuilder,
      (CheckIn, BaseReferences<_$AppDatabase, $CareerJournalTable, CheckIn>),
      CheckIn,
      PrefetchHooks Function()
    >;
typedef $$CareerStoriesTableCreateCompanionBuilder =
    CareerStoriesCompanion Function({
      required String id,
      Value<String> hlc,
      Value<bool> deleted,
      required String title,
      Value<String> situation,
      Value<String> task,
      Value<String> action,
      Value<String> result,
      Value<String> competencies,
      Value<String> source,
      Value<String?> sourceId,
      Value<String> criteria,
      Value<bool> confirmed,
      required String added,
      Value<int> rowid,
    });
typedef $$CareerStoriesTableUpdateCompanionBuilder =
    CareerStoriesCompanion Function({
      Value<String> id,
      Value<String> hlc,
      Value<bool> deleted,
      Value<String> title,
      Value<String> situation,
      Value<String> task,
      Value<String> action,
      Value<String> result,
      Value<String> competencies,
      Value<String> source,
      Value<String?> sourceId,
      Value<String> criteria,
      Value<bool> confirmed,
      Value<String> added,
      Value<int> rowid,
    });

class $$CareerStoriesTableFilterComposer
    extends Composer<_$AppDatabase, $CareerStoriesTable> {
  $$CareerStoriesTableFilterComposer({
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

  ColumnFilters<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get situation => $composableBuilder(
    column: $table.situation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get task => $composableBuilder(
    column: $table.task,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get action => $composableBuilder(
    column: $table.action,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get result => $composableBuilder(
    column: $table.result,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get competencies => $composableBuilder(
    column: $table.competencies,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get criteria => $composableBuilder(
    column: $table.criteria,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get confirmed => $composableBuilder(
    column: $table.confirmed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get added => $composableBuilder(
    column: $table.added,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CareerStoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $CareerStoriesTable> {
  $$CareerStoriesTableOrderingComposer({
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

  ColumnOrderings<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get situation => $composableBuilder(
    column: $table.situation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get task => $composableBuilder(
    column: $table.task,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get action => $composableBuilder(
    column: $table.action,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get result => $composableBuilder(
    column: $table.result,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get competencies => $composableBuilder(
    column: $table.competencies,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get criteria => $composableBuilder(
    column: $table.criteria,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get confirmed => $composableBuilder(
    column: $table.confirmed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get added => $composableBuilder(
    column: $table.added,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CareerStoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CareerStoriesTable> {
  $$CareerStoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get hlc =>
      $composableBuilder(column: $table.hlc, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get situation =>
      $composableBuilder(column: $table.situation, builder: (column) => column);

  GeneratedColumn<String> get task =>
      $composableBuilder(column: $table.task, builder: (column) => column);

  GeneratedColumn<String> get action =>
      $composableBuilder(column: $table.action, builder: (column) => column);

  GeneratedColumn<String> get result =>
      $composableBuilder(column: $table.result, builder: (column) => column);

  GeneratedColumn<String> get competencies => $composableBuilder(
    column: $table.competencies,
    builder: (column) => column,
  );

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get sourceId =>
      $composableBuilder(column: $table.sourceId, builder: (column) => column);

  GeneratedColumn<String> get criteria =>
      $composableBuilder(column: $table.criteria, builder: (column) => column);

  GeneratedColumn<bool> get confirmed =>
      $composableBuilder(column: $table.confirmed, builder: (column) => column);

  GeneratedColumn<String> get added =>
      $composableBuilder(column: $table.added, builder: (column) => column);
}

class $$CareerStoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CareerStoriesTable,
          Story,
          $$CareerStoriesTableFilterComposer,
          $$CareerStoriesTableOrderingComposer,
          $$CareerStoriesTableAnnotationComposer,
          $$CareerStoriesTableCreateCompanionBuilder,
          $$CareerStoriesTableUpdateCompanionBuilder,
          (Story, BaseReferences<_$AppDatabase, $CareerStoriesTable, Story>),
          Story,
          PrefetchHooks Function()
        > {
  $$CareerStoriesTableTableManager(_$AppDatabase db, $CareerStoriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CareerStoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CareerStoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CareerStoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> hlc = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> situation = const Value.absent(),
                Value<String> task = const Value.absent(),
                Value<String> action = const Value.absent(),
                Value<String> result = const Value.absent(),
                Value<String> competencies = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String?> sourceId = const Value.absent(),
                Value<String> criteria = const Value.absent(),
                Value<bool> confirmed = const Value.absent(),
                Value<String> added = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CareerStoriesCompanion(
                id: id,
                hlc: hlc,
                deleted: deleted,
                title: title,
                situation: situation,
                task: task,
                action: action,
                result: result,
                competencies: competencies,
                source: source,
                sourceId: sourceId,
                criteria: criteria,
                confirmed: confirmed,
                added: added,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String> hlc = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                required String title,
                Value<String> situation = const Value.absent(),
                Value<String> task = const Value.absent(),
                Value<String> action = const Value.absent(),
                Value<String> result = const Value.absent(),
                Value<String> competencies = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String?> sourceId = const Value.absent(),
                Value<String> criteria = const Value.absent(),
                Value<bool> confirmed = const Value.absent(),
                required String added,
                Value<int> rowid = const Value.absent(),
              }) => CareerStoriesCompanion.insert(
                id: id,
                hlc: hlc,
                deleted: deleted,
                title: title,
                situation: situation,
                task: task,
                action: action,
                result: result,
                competencies: competencies,
                source: source,
                sourceId: sourceId,
                criteria: criteria,
                confirmed: confirmed,
                added: added,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CareerStoriesTable, Story>(table),
                  BaseReferences<_$AppDatabase, $CareerStoriesTable, Story>(
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

typedef $$CareerStoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CareerStoriesTable,
      Story,
      $$CareerStoriesTableFilterComposer,
      $$CareerStoriesTableOrderingComposer,
      $$CareerStoriesTableAnnotationComposer,
      $$CareerStoriesTableCreateCompanionBuilder,
      $$CareerStoriesTableUpdateCompanionBuilder,
      (Story, BaseReferences<_$AppDatabase, $CareerStoriesTable, Story>),
      Story,
      PrefetchHooks Function()
    >;
typedef $$ContactHandlesTableCreateCompanionBuilder =
    ContactHandlesCompanion Function({
      required String id,
      Value<String> hlc,
      Value<bool> deleted,
      required String contactId,
      required String channel,
      required String handle,
      Value<String> account,
      Value<bool> primary,
      Value<int> rowid,
    });
typedef $$ContactHandlesTableUpdateCompanionBuilder =
    ContactHandlesCompanion Function({
      Value<String> id,
      Value<String> hlc,
      Value<bool> deleted,
      Value<String> contactId,
      Value<String> channel,
      Value<String> handle,
      Value<String> account,
      Value<bool> primary,
      Value<int> rowid,
    });

class $$ContactHandlesTableFilterComposer
    extends Composer<_$AppDatabase, $ContactHandlesTable> {
  $$ContactHandlesTableFilterComposer({
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

  ColumnFilters<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contactId => $composableBuilder(
    column: $table.contactId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get channel => $composableBuilder(
    column: $table.channel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get handle => $composableBuilder(
    column: $table.handle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get account => $composableBuilder(
    column: $table.account,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get primary => $composableBuilder(
    column: $table.primary,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ContactHandlesTableOrderingComposer
    extends Composer<_$AppDatabase, $ContactHandlesTable> {
  $$ContactHandlesTableOrderingComposer({
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

  ColumnOrderings<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contactId => $composableBuilder(
    column: $table.contactId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get channel => $composableBuilder(
    column: $table.channel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get handle => $composableBuilder(
    column: $table.handle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get account => $composableBuilder(
    column: $table.account,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get primary => $composableBuilder(
    column: $table.primary,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ContactHandlesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ContactHandlesTable> {
  $$ContactHandlesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get hlc =>
      $composableBuilder(column: $table.hlc, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<String> get contactId =>
      $composableBuilder(column: $table.contactId, builder: (column) => column);

  GeneratedColumn<String> get channel =>
      $composableBuilder(column: $table.channel, builder: (column) => column);

  GeneratedColumn<String> get handle =>
      $composableBuilder(column: $table.handle, builder: (column) => column);

  GeneratedColumn<String> get account =>
      $composableBuilder(column: $table.account, builder: (column) => column);

  GeneratedColumn<bool> get primary =>
      $composableBuilder(column: $table.primary, builder: (column) => column);
}

class $$ContactHandlesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ContactHandlesTable,
          ContactHandle,
          $$ContactHandlesTableFilterComposer,
          $$ContactHandlesTableOrderingComposer,
          $$ContactHandlesTableAnnotationComposer,
          $$ContactHandlesTableCreateCompanionBuilder,
          $$ContactHandlesTableUpdateCompanionBuilder,
          (
            ContactHandle,
            BaseReferences<_$AppDatabase, $ContactHandlesTable, ContactHandle>,
          ),
          ContactHandle,
          PrefetchHooks Function()
        > {
  $$ContactHandlesTableTableManager(
    _$AppDatabase db,
    $ContactHandlesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ContactHandlesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ContactHandlesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ContactHandlesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> hlc = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<String> contactId = const Value.absent(),
                Value<String> channel = const Value.absent(),
                Value<String> handle = const Value.absent(),
                Value<String> account = const Value.absent(),
                Value<bool> primary = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ContactHandlesCompanion(
                id: id,
                hlc: hlc,
                deleted: deleted,
                contactId: contactId,
                channel: channel,
                handle: handle,
                account: account,
                primary: primary,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String> hlc = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                required String contactId,
                required String channel,
                required String handle,
                Value<String> account = const Value.absent(),
                Value<bool> primary = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ContactHandlesCompanion.insert(
                id: id,
                hlc: hlc,
                deleted: deleted,
                contactId: contactId,
                channel: channel,
                handle: handle,
                account: account,
                primary: primary,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ContactHandlesTable, ContactHandle>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $ContactHandlesTable,
                    ContactHandle
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ContactHandlesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ContactHandlesTable,
      ContactHandle,
      $$ContactHandlesTableFilterComposer,
      $$ContactHandlesTableOrderingComposer,
      $$ContactHandlesTableAnnotationComposer,
      $$ContactHandlesTableCreateCompanionBuilder,
      $$ContactHandlesTableUpdateCompanionBuilder,
      (
        ContactHandle,
        BaseReferences<_$AppDatabase, $ContactHandlesTable, ContactHandle>,
      ),
      ContactHandle,
      PrefetchHooks Function()
    >;
typedef $$ConversationsTableCreateCompanionBuilder =
    ConversationsCompanion Function({
      required String id,
      Value<String> hlc,
      Value<bool> deleted,
      Value<String?> contactId,
      required String channel,
      Value<String> account,
      Value<String> mode,
      Value<String?> externalId,
      Value<String> peer,
      Value<String> subject,
      Value<String> status,
      Value<String?> followUp,
      Value<String?> jobId,
      required String lastAt,
      Value<int> unread,
      Value<int> rowid,
    });
typedef $$ConversationsTableUpdateCompanionBuilder =
    ConversationsCompanion Function({
      Value<String> id,
      Value<String> hlc,
      Value<bool> deleted,
      Value<String?> contactId,
      Value<String> channel,
      Value<String> account,
      Value<String> mode,
      Value<String?> externalId,
      Value<String> peer,
      Value<String> subject,
      Value<String> status,
      Value<String?> followUp,
      Value<String?> jobId,
      Value<String> lastAt,
      Value<int> unread,
      Value<int> rowid,
    });

class $$ConversationsTableFilterComposer
    extends Composer<_$AppDatabase, $ConversationsTable> {
  $$ConversationsTableFilterComposer({
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

  ColumnFilters<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contactId => $composableBuilder(
    column: $table.contactId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get channel => $composableBuilder(
    column: $table.channel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get account => $composableBuilder(
    column: $table.account,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get externalId => $composableBuilder(
    column: $table.externalId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get peer => $composableBuilder(
    column: $table.peer,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subject => $composableBuilder(
    column: $table.subject,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get followUp => $composableBuilder(
    column: $table.followUp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get jobId => $composableBuilder(
    column: $table.jobId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastAt => $composableBuilder(
    column: $table.lastAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get unread => $composableBuilder(
    column: $table.unread,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ConversationsTableOrderingComposer
    extends Composer<_$AppDatabase, $ConversationsTable> {
  $$ConversationsTableOrderingComposer({
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

  ColumnOrderings<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contactId => $composableBuilder(
    column: $table.contactId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get channel => $composableBuilder(
    column: $table.channel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get account => $composableBuilder(
    column: $table.account,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get externalId => $composableBuilder(
    column: $table.externalId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get peer => $composableBuilder(
    column: $table.peer,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subject => $composableBuilder(
    column: $table.subject,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get followUp => $composableBuilder(
    column: $table.followUp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get jobId => $composableBuilder(
    column: $table.jobId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastAt => $composableBuilder(
    column: $table.lastAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get unread => $composableBuilder(
    column: $table.unread,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ConversationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ConversationsTable> {
  $$ConversationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get hlc =>
      $composableBuilder(column: $table.hlc, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<String> get contactId =>
      $composableBuilder(column: $table.contactId, builder: (column) => column);

  GeneratedColumn<String> get channel =>
      $composableBuilder(column: $table.channel, builder: (column) => column);

  GeneratedColumn<String> get account =>
      $composableBuilder(column: $table.account, builder: (column) => column);

  GeneratedColumn<String> get mode =>
      $composableBuilder(column: $table.mode, builder: (column) => column);

  GeneratedColumn<String> get externalId => $composableBuilder(
    column: $table.externalId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get peer =>
      $composableBuilder(column: $table.peer, builder: (column) => column);

  GeneratedColumn<String> get subject =>
      $composableBuilder(column: $table.subject, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get followUp =>
      $composableBuilder(column: $table.followUp, builder: (column) => column);

  GeneratedColumn<String> get jobId =>
      $composableBuilder(column: $table.jobId, builder: (column) => column);

  GeneratedColumn<String> get lastAt =>
      $composableBuilder(column: $table.lastAt, builder: (column) => column);

  GeneratedColumn<int> get unread =>
      $composableBuilder(column: $table.unread, builder: (column) => column);
}

class $$ConversationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ConversationsTable,
          Conversation,
          $$ConversationsTableFilterComposer,
          $$ConversationsTableOrderingComposer,
          $$ConversationsTableAnnotationComposer,
          $$ConversationsTableCreateCompanionBuilder,
          $$ConversationsTableUpdateCompanionBuilder,
          (
            Conversation,
            BaseReferences<_$AppDatabase, $ConversationsTable, Conversation>,
          ),
          Conversation,
          PrefetchHooks Function()
        > {
  $$ConversationsTableTableManager(_$AppDatabase db, $ConversationsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ConversationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ConversationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ConversationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> hlc = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<String?> contactId = const Value.absent(),
                Value<String> channel = const Value.absent(),
                Value<String> account = const Value.absent(),
                Value<String> mode = const Value.absent(),
                Value<String?> externalId = const Value.absent(),
                Value<String> peer = const Value.absent(),
                Value<String> subject = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> followUp = const Value.absent(),
                Value<String?> jobId = const Value.absent(),
                Value<String> lastAt = const Value.absent(),
                Value<int> unread = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ConversationsCompanion(
                id: id,
                hlc: hlc,
                deleted: deleted,
                contactId: contactId,
                channel: channel,
                account: account,
                mode: mode,
                externalId: externalId,
                peer: peer,
                subject: subject,
                status: status,
                followUp: followUp,
                jobId: jobId,
                lastAt: lastAt,
                unread: unread,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String> hlc = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<String?> contactId = const Value.absent(),
                required String channel,
                Value<String> account = const Value.absent(),
                Value<String> mode = const Value.absent(),
                Value<String?> externalId = const Value.absent(),
                Value<String> peer = const Value.absent(),
                Value<String> subject = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> followUp = const Value.absent(),
                Value<String?> jobId = const Value.absent(),
                required String lastAt,
                Value<int> unread = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ConversationsCompanion.insert(
                id: id,
                hlc: hlc,
                deleted: deleted,
                contactId: contactId,
                channel: channel,
                account: account,
                mode: mode,
                externalId: externalId,
                peer: peer,
                subject: subject,
                status: status,
                followUp: followUp,
                jobId: jobId,
                lastAt: lastAt,
                unread: unread,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ConversationsTable, Conversation>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $ConversationsTable,
                    Conversation
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ConversationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ConversationsTable,
      Conversation,
      $$ConversationsTableFilterComposer,
      $$ConversationsTableOrderingComposer,
      $$ConversationsTableAnnotationComposer,
      $$ConversationsTableCreateCompanionBuilder,
      $$ConversationsTableUpdateCompanionBuilder,
      (
        Conversation,
        BaseReferences<_$AppDatabase, $ConversationsTable, Conversation>,
      ),
      Conversation,
      PrefetchHooks Function()
    >;
typedef $$MessagesTableCreateCompanionBuilder = MessagesCompanion Function({
  required String id,
  Value<String> hlc,
  Value<bool> deleted,
  required String conversationId,
  required String direction,
  Value<String> body,
  required String sentAt,
  Value<String> source,
  Value<String> status,
  Value<String?> externalId,
  Value<String?> inReplyTo,
  Value<String?> draftOf,
  Value<int> rowid,
});
typedef $$MessagesTableUpdateCompanionBuilder = MessagesCompanion Function({
  Value<String> id,
  Value<String> hlc,
  Value<bool> deleted,
  Value<String> conversationId,
  Value<String> direction,
  Value<String> body,
  Value<String> sentAt,
  Value<String> source,
  Value<String> status,
  Value<String?> externalId,
  Value<String?> inReplyTo,
  Value<String?> draftOf,
  Value<int> rowid,
});

class $$MessagesTableFilterComposer
    extends Composer<_$AppDatabase, $MessagesTable> {
  $$MessagesTableFilterComposer({
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

  ColumnFilters<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get conversationId => $composableBuilder(
    column: $table.conversationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get direction => $composableBuilder(
    column: $table.direction,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sentAt => $composableBuilder(
    column: $table.sentAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get externalId => $composableBuilder(
    column: $table.externalId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get inReplyTo => $composableBuilder(
    column: $table.inReplyTo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get draftOf => $composableBuilder(
    column: $table.draftOf,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MessagesTableOrderingComposer
    extends Composer<_$AppDatabase, $MessagesTable> {
  $$MessagesTableOrderingComposer({
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

  ColumnOrderings<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get conversationId => $composableBuilder(
    column: $table.conversationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get direction => $composableBuilder(
    column: $table.direction,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sentAt => $composableBuilder(
    column: $table.sentAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get externalId => $composableBuilder(
    column: $table.externalId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get inReplyTo => $composableBuilder(
    column: $table.inReplyTo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get draftOf => $composableBuilder(
    column: $table.draftOf,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MessagesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MessagesTable> {
  $$MessagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get hlc =>
      $composableBuilder(column: $table.hlc, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<String> get conversationId => $composableBuilder(
    column: $table.conversationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get direction =>
      $composableBuilder(column: $table.direction, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<String> get sentAt =>
      $composableBuilder(column: $table.sentAt, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get externalId => $composableBuilder(
    column: $table.externalId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get inReplyTo =>
      $composableBuilder(column: $table.inReplyTo, builder: (column) => column);

  GeneratedColumn<String> get draftOf =>
      $composableBuilder(column: $table.draftOf, builder: (column) => column);
}

class $$MessagesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MessagesTable,
          ThreadMessage,
          $$MessagesTableFilterComposer,
          $$MessagesTableOrderingComposer,
          $$MessagesTableAnnotationComposer,
          $$MessagesTableCreateCompanionBuilder,
          $$MessagesTableUpdateCompanionBuilder,
          (
            ThreadMessage,
            BaseReferences<_$AppDatabase, $MessagesTable, ThreadMessage>,
          ),
          ThreadMessage,
          PrefetchHooks Function()
        > {
  $$MessagesTableTableManager(_$AppDatabase db, $MessagesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MessagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MessagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MessagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> hlc = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<String> conversationId = const Value.absent(),
                Value<String> direction = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<String> sentAt = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> externalId = const Value.absent(),
                Value<String?> inReplyTo = const Value.absent(),
                Value<String?> draftOf = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MessagesCompanion(
                id: id,
                hlc: hlc,
                deleted: deleted,
                conversationId: conversationId,
                direction: direction,
                body: body,
                sentAt: sentAt,
                source: source,
                status: status,
                externalId: externalId,
                inReplyTo: inReplyTo,
                draftOf: draftOf,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String> hlc = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                required String conversationId,
                required String direction,
                Value<String> body = const Value.absent(),
                required String sentAt,
                Value<String> source = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> externalId = const Value.absent(),
                Value<String?> inReplyTo = const Value.absent(),
                Value<String?> draftOf = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MessagesCompanion.insert(
                id: id,
                hlc: hlc,
                deleted: deleted,
                conversationId: conversationId,
                direction: direction,
                body: body,
                sentAt: sentAt,
                source: source,
                status: status,
                externalId: externalId,
                inReplyTo: inReplyTo,
                draftOf: draftOf,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MessagesTable, ThreadMessage>(table),
                  BaseReferences<_$AppDatabase, $MessagesTable, ThreadMessage>(
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

typedef $$MessagesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MessagesTable,
      ThreadMessage,
      $$MessagesTableFilterComposer,
      $$MessagesTableOrderingComposer,
      $$MessagesTableAnnotationComposer,
      $$MessagesTableCreateCompanionBuilder,
      $$MessagesTableUpdateCompanionBuilder,
      (
        ThreadMessage,
        BaseReferences<_$AppDatabase, $MessagesTable, ThreadMessage>,
      ),
      ThreadMessage,
      PrefetchHooks Function()
    >;
typedef $$CareerPostsTableCreateCompanionBuilder =
    CareerPostsCompanion Function({
      required String id,
      Value<String> hlc,
      Value<bool> deleted,
      Value<String> channel,
      required String at,
      Value<String> topic,
      Value<String> body,
      Value<String> humanized,
      Value<String> status,
      Value<String> postUrl,
      Value<String?> postedAt,
      Value<int> rowid,
    });
typedef $$CareerPostsTableUpdateCompanionBuilder =
    CareerPostsCompanion Function({
      Value<String> id,
      Value<String> hlc,
      Value<bool> deleted,
      Value<String> channel,
      Value<String> at,
      Value<String> topic,
      Value<String> body,
      Value<String> humanized,
      Value<String> status,
      Value<String> postUrl,
      Value<String?> postedAt,
      Value<int> rowid,
    });

class $$CareerPostsTableFilterComposer
    extends Composer<_$AppDatabase, $CareerPostsTable> {
  $$CareerPostsTableFilterComposer({
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

  ColumnFilters<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get channel => $composableBuilder(
    column: $table.channel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get topic => $composableBuilder(
    column: $table.topic,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get humanized => $composableBuilder(
    column: $table.humanized,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get postUrl => $composableBuilder(
    column: $table.postUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get postedAt => $composableBuilder(
    column: $table.postedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CareerPostsTableOrderingComposer
    extends Composer<_$AppDatabase, $CareerPostsTable> {
  $$CareerPostsTableOrderingComposer({
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

  ColumnOrderings<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get channel => $composableBuilder(
    column: $table.channel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get topic => $composableBuilder(
    column: $table.topic,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get humanized => $composableBuilder(
    column: $table.humanized,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get postUrl => $composableBuilder(
    column: $table.postUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get postedAt => $composableBuilder(
    column: $table.postedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CareerPostsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CareerPostsTable> {
  $$CareerPostsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get hlc =>
      $composableBuilder(column: $table.hlc, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<String> get channel =>
      $composableBuilder(column: $table.channel, builder: (column) => column);

  GeneratedColumn<String> get at =>
      $composableBuilder(column: $table.at, builder: (column) => column);

  GeneratedColumn<String> get topic =>
      $composableBuilder(column: $table.topic, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<String> get humanized =>
      $composableBuilder(column: $table.humanized, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get postUrl =>
      $composableBuilder(column: $table.postUrl, builder: (column) => column);

  GeneratedColumn<String> get postedAt =>
      $composableBuilder(column: $table.postedAt, builder: (column) => column);
}

class $$CareerPostsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CareerPostsTable,
          PlannedPost,
          $$CareerPostsTableFilterComposer,
          $$CareerPostsTableOrderingComposer,
          $$CareerPostsTableAnnotationComposer,
          $$CareerPostsTableCreateCompanionBuilder,
          $$CareerPostsTableUpdateCompanionBuilder,
          (
            PlannedPost,
            BaseReferences<_$AppDatabase, $CareerPostsTable, PlannedPost>,
          ),
          PlannedPost,
          PrefetchHooks Function()
        > {
  $$CareerPostsTableTableManager(_$AppDatabase db, $CareerPostsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CareerPostsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CareerPostsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CareerPostsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> hlc = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<String> channel = const Value.absent(),
                Value<String> at = const Value.absent(),
                Value<String> topic = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<String> humanized = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> postUrl = const Value.absent(),
                Value<String?> postedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CareerPostsCompanion(
                id: id,
                hlc: hlc,
                deleted: deleted,
                channel: channel,
                at: at,
                topic: topic,
                body: body,
                humanized: humanized,
                status: status,
                postUrl: postUrl,
                postedAt: postedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String> hlc = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<String> channel = const Value.absent(),
                required String at,
                Value<String> topic = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<String> humanized = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> postUrl = const Value.absent(),
                Value<String?> postedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CareerPostsCompanion.insert(
                id: id,
                hlc: hlc,
                deleted: deleted,
                channel: channel,
                at: at,
                topic: topic,
                body: body,
                humanized: humanized,
                status: status,
                postUrl: postUrl,
                postedAt: postedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CareerPostsTable, PlannedPost>(table),
                  BaseReferences<_$AppDatabase, $CareerPostsTable, PlannedPost>(
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

typedef $$CareerPostsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CareerPostsTable,
      PlannedPost,
      $$CareerPostsTableFilterComposer,
      $$CareerPostsTableOrderingComposer,
      $$CareerPostsTableAnnotationComposer,
      $$CareerPostsTableCreateCompanionBuilder,
      $$CareerPostsTableUpdateCompanionBuilder,
      (
        PlannedPost,
        BaseReferences<_$AppDatabase, $CareerPostsTable, PlannedPost>,
      ),
      PlannedPost,
      PrefetchHooks Function()
    >;
typedef $$CareerTracksTableCreateCompanionBuilder =
    CareerTracksCompanion Function({
      required String id,
      Value<String> hlc,
      Value<bool> deleted,
      required String country,
      Value<String> routeId,
      required String title,
      Value<String> status,
      Value<String> trigger,
      Value<String> milestones,
      Value<String> notes,
      required String added,
      Value<int> rowid,
    });
typedef $$CareerTracksTableUpdateCompanionBuilder =
    CareerTracksCompanion Function({
      Value<String> id,
      Value<String> hlc,
      Value<bool> deleted,
      Value<String> country,
      Value<String> routeId,
      Value<String> title,
      Value<String> status,
      Value<String> trigger,
      Value<String> milestones,
      Value<String> notes,
      Value<String> added,
      Value<int> rowid,
    });

class $$CareerTracksTableFilterComposer
    extends Composer<_$AppDatabase, $CareerTracksTable> {
  $$CareerTracksTableFilterComposer({
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

  ColumnFilters<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get country => $composableBuilder(
    column: $table.country,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get routeId => $composableBuilder(
    column: $table.routeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get trigger => $composableBuilder(
    column: $table.trigger,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get milestones => $composableBuilder(
    column: $table.milestones,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get added => $composableBuilder(
    column: $table.added,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CareerTracksTableOrderingComposer
    extends Composer<_$AppDatabase, $CareerTracksTable> {
  $$CareerTracksTableOrderingComposer({
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

  ColumnOrderings<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get country => $composableBuilder(
    column: $table.country,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get routeId => $composableBuilder(
    column: $table.routeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get trigger => $composableBuilder(
    column: $table.trigger,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get milestones => $composableBuilder(
    column: $table.milestones,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get added => $composableBuilder(
    column: $table.added,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CareerTracksTableAnnotationComposer
    extends Composer<_$AppDatabase, $CareerTracksTable> {
  $$CareerTracksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get hlc =>
      $composableBuilder(column: $table.hlc, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<String> get country =>
      $composableBuilder(column: $table.country, builder: (column) => column);

  GeneratedColumn<String> get routeId =>
      $composableBuilder(column: $table.routeId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get trigger =>
      $composableBuilder(column: $table.trigger, builder: (column) => column);

  GeneratedColumn<String> get milestones => $composableBuilder(
    column: $table.milestones,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get added =>
      $composableBuilder(column: $table.added, builder: (column) => column);
}

class $$CareerTracksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CareerTracksTable,
          RouteTrack,
          $$CareerTracksTableFilterComposer,
          $$CareerTracksTableOrderingComposer,
          $$CareerTracksTableAnnotationComposer,
          $$CareerTracksTableCreateCompanionBuilder,
          $$CareerTracksTableUpdateCompanionBuilder,
          (
            RouteTrack,
            BaseReferences<_$AppDatabase, $CareerTracksTable, RouteTrack>,
          ),
          RouteTrack,
          PrefetchHooks Function()
        > {
  $$CareerTracksTableTableManager(_$AppDatabase db, $CareerTracksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CareerTracksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CareerTracksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CareerTracksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> hlc = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<String> country = const Value.absent(),
                Value<String> routeId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> trigger = const Value.absent(),
                Value<String> milestones = const Value.absent(),
                Value<String> notes = const Value.absent(),
                Value<String> added = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CareerTracksCompanion(
                id: id,
                hlc: hlc,
                deleted: deleted,
                country: country,
                routeId: routeId,
                title: title,
                status: status,
                trigger: trigger,
                milestones: milestones,
                notes: notes,
                added: added,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String> hlc = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                required String country,
                Value<String> routeId = const Value.absent(),
                required String title,
                Value<String> status = const Value.absent(),
                Value<String> trigger = const Value.absent(),
                Value<String> milestones = const Value.absent(),
                Value<String> notes = const Value.absent(),
                required String added,
                Value<int> rowid = const Value.absent(),
              }) => CareerTracksCompanion.insert(
                id: id,
                hlc: hlc,
                deleted: deleted,
                country: country,
                routeId: routeId,
                title: title,
                status: status,
                trigger: trigger,
                milestones: milestones,
                notes: notes,
                added: added,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CareerTracksTable, RouteTrack>(table),
                  BaseReferences<_$AppDatabase, $CareerTracksTable, RouteTrack>(
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

typedef $$CareerTracksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CareerTracksTable,
      RouteTrack,
      $$CareerTracksTableFilterComposer,
      $$CareerTracksTableOrderingComposer,
      $$CareerTracksTableAnnotationComposer,
      $$CareerTracksTableCreateCompanionBuilder,
      $$CareerTracksTableUpdateCompanionBuilder,
      (
        RouteTrack,
        BaseReferences<_$AppDatabase, $CareerTracksTable, RouteTrack>,
      ),
      RouteTrack,
      PrefetchHooks Function()
    >;
typedef $$CareerRoleProfilesTableCreateCompanionBuilder =
    CareerRoleProfilesCompanion Function({
      required String id,
      Value<String> hlc,
      Value<bool> deleted,
      required String title,
      Value<String> employer,
      Value<String?> jobId,
      Value<String> framework,
      Value<String> criteria,
      Value<String> source,
      required String added,
      required String updated,
      Value<int> rowid,
    });
typedef $$CareerRoleProfilesTableUpdateCompanionBuilder =
    CareerRoleProfilesCompanion Function({
      Value<String> id,
      Value<String> hlc,
      Value<bool> deleted,
      Value<String> title,
      Value<String> employer,
      Value<String?> jobId,
      Value<String> framework,
      Value<String> criteria,
      Value<String> source,
      Value<String> added,
      Value<String> updated,
      Value<int> rowid,
    });

class $$CareerRoleProfilesTableFilterComposer
    extends Composer<_$AppDatabase, $CareerRoleProfilesTable> {
  $$CareerRoleProfilesTableFilterComposer({
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

  ColumnFilters<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get employer => $composableBuilder(
    column: $table.employer,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get jobId => $composableBuilder(
    column: $table.jobId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get framework => $composableBuilder(
    column: $table.framework,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get criteria => $composableBuilder(
    column: $table.criteria,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get added => $composableBuilder(
    column: $table.added,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updated => $composableBuilder(
    column: $table.updated,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CareerRoleProfilesTableOrderingComposer
    extends Composer<_$AppDatabase, $CareerRoleProfilesTable> {
  $$CareerRoleProfilesTableOrderingComposer({
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

  ColumnOrderings<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get employer => $composableBuilder(
    column: $table.employer,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get jobId => $composableBuilder(
    column: $table.jobId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get framework => $composableBuilder(
    column: $table.framework,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get criteria => $composableBuilder(
    column: $table.criteria,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get added => $composableBuilder(
    column: $table.added,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updated => $composableBuilder(
    column: $table.updated,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CareerRoleProfilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CareerRoleProfilesTable> {
  $$CareerRoleProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get hlc =>
      $composableBuilder(column: $table.hlc, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get employer =>
      $composableBuilder(column: $table.employer, builder: (column) => column);

  GeneratedColumn<String> get jobId =>
      $composableBuilder(column: $table.jobId, builder: (column) => column);

  GeneratedColumn<String> get framework =>
      $composableBuilder(column: $table.framework, builder: (column) => column);

  GeneratedColumn<String> get criteria =>
      $composableBuilder(column: $table.criteria, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get added =>
      $composableBuilder(column: $table.added, builder: (column) => column);

  GeneratedColumn<String> get updated =>
      $composableBuilder(column: $table.updated, builder: (column) => column);
}

class $$CareerRoleProfilesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CareerRoleProfilesTable,
          RoleProfileRow,
          $$CareerRoleProfilesTableFilterComposer,
          $$CareerRoleProfilesTableOrderingComposer,
          $$CareerRoleProfilesTableAnnotationComposer,
          $$CareerRoleProfilesTableCreateCompanionBuilder,
          $$CareerRoleProfilesTableUpdateCompanionBuilder,
          (
            RoleProfileRow,
            BaseReferences<
              _$AppDatabase,
              $CareerRoleProfilesTable,
              RoleProfileRow
            >,
          ),
          RoleProfileRow,
          PrefetchHooks Function()
        > {
  $$CareerRoleProfilesTableTableManager(
    _$AppDatabase db,
    $CareerRoleProfilesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CareerRoleProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CareerRoleProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CareerRoleProfilesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> hlc = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> employer = const Value.absent(),
                Value<String?> jobId = const Value.absent(),
                Value<String> framework = const Value.absent(),
                Value<String> criteria = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String> added = const Value.absent(),
                Value<String> updated = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CareerRoleProfilesCompanion(
                id: id,
                hlc: hlc,
                deleted: deleted,
                title: title,
                employer: employer,
                jobId: jobId,
                framework: framework,
                criteria: criteria,
                source: source,
                added: added,
                updated: updated,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String> hlc = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                required String title,
                Value<String> employer = const Value.absent(),
                Value<String?> jobId = const Value.absent(),
                Value<String> framework = const Value.absent(),
                Value<String> criteria = const Value.absent(),
                Value<String> source = const Value.absent(),
                required String added,
                required String updated,
                Value<int> rowid = const Value.absent(),
              }) => CareerRoleProfilesCompanion.insert(
                id: id,
                hlc: hlc,
                deleted: deleted,
                title: title,
                employer: employer,
                jobId: jobId,
                framework: framework,
                criteria: criteria,
                source: source,
                added: added,
                updated: updated,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CareerRoleProfilesTable, RoleProfileRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $CareerRoleProfilesTable,
                    RoleProfileRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CareerRoleProfilesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CareerRoleProfilesTable,
      RoleProfileRow,
      $$CareerRoleProfilesTableFilterComposer,
      $$CareerRoleProfilesTableOrderingComposer,
      $$CareerRoleProfilesTableAnnotationComposer,
      $$CareerRoleProfilesTableCreateCompanionBuilder,
      $$CareerRoleProfilesTableUpdateCompanionBuilder,
      (
        RoleProfileRow,
        BaseReferences<_$AppDatabase, $CareerRoleProfilesTable, RoleProfileRow>,
      ),
      RoleProfileRow,
      PrefetchHooks Function()
    >;
typedef $$CareerProcessesTableCreateCompanionBuilder =
    CareerProcessesCompanion Function({
      required String id,
      Value<String> hlc,
      Value<bool> deleted,
      required String name,
      Value<String> template,
      Value<String?> profileId,
      required String process,
      Value<String> progress,
      required String started,
      required String updated,
      Value<int> rowid,
    });
typedef $$CareerProcessesTableUpdateCompanionBuilder =
    CareerProcessesCompanion Function({
      Value<String> id,
      Value<String> hlc,
      Value<bool> deleted,
      Value<String> name,
      Value<String> template,
      Value<String?> profileId,
      Value<String> process,
      Value<String> progress,
      Value<String> started,
      Value<String> updated,
      Value<int> rowid,
    });

class $$CareerProcessesTableFilterComposer
    extends Composer<_$AppDatabase, $CareerProcessesTable> {
  $$CareerProcessesTableFilterComposer({
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

  ColumnFilters<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get template => $composableBuilder(
    column: $table.template,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get profileId => $composableBuilder(
    column: $table.profileId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get process => $composableBuilder(
    column: $table.process,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get progress => $composableBuilder(
    column: $table.progress,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get started => $composableBuilder(
    column: $table.started,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updated => $composableBuilder(
    column: $table.updated,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CareerProcessesTableOrderingComposer
    extends Composer<_$AppDatabase, $CareerProcessesTable> {
  $$CareerProcessesTableOrderingComposer({
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

  ColumnOrderings<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get template => $composableBuilder(
    column: $table.template,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get profileId => $composableBuilder(
    column: $table.profileId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get process => $composableBuilder(
    column: $table.process,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get progress => $composableBuilder(
    column: $table.progress,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get started => $composableBuilder(
    column: $table.started,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updated => $composableBuilder(
    column: $table.updated,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CareerProcessesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CareerProcessesTable> {
  $$CareerProcessesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get hlc =>
      $composableBuilder(column: $table.hlc, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get template =>
      $composableBuilder(column: $table.template, builder: (column) => column);

  GeneratedColumn<String> get profileId =>
      $composableBuilder(column: $table.profileId, builder: (column) => column);

  GeneratedColumn<String> get process =>
      $composableBuilder(column: $table.process, builder: (column) => column);

  GeneratedColumn<String> get progress =>
      $composableBuilder(column: $table.progress, builder: (column) => column);

  GeneratedColumn<String> get started =>
      $composableBuilder(column: $table.started, builder: (column) => column);

  GeneratedColumn<String> get updated =>
      $composableBuilder(column: $table.updated, builder: (column) => column);
}

class $$CareerProcessesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CareerProcessesTable,
          ProcessRow,
          $$CareerProcessesTableFilterComposer,
          $$CareerProcessesTableOrderingComposer,
          $$CareerProcessesTableAnnotationComposer,
          $$CareerProcessesTableCreateCompanionBuilder,
          $$CareerProcessesTableUpdateCompanionBuilder,
          (
            ProcessRow,
            BaseReferences<_$AppDatabase, $CareerProcessesTable, ProcessRow>,
          ),
          ProcessRow,
          PrefetchHooks Function()
        > {
  $$CareerProcessesTableTableManager(
    _$AppDatabase db,
    $CareerProcessesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CareerProcessesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CareerProcessesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CareerProcessesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> hlc = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> template = const Value.absent(),
                Value<String?> profileId = const Value.absent(),
                Value<String> process = const Value.absent(),
                Value<String> progress = const Value.absent(),
                Value<String> started = const Value.absent(),
                Value<String> updated = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CareerProcessesCompanion(
                id: id,
                hlc: hlc,
                deleted: deleted,
                name: name,
                template: template,
                profileId: profileId,
                process: process,
                progress: progress,
                started: started,
                updated: updated,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String> hlc = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                required String name,
                Value<String> template = const Value.absent(),
                Value<String?> profileId = const Value.absent(),
                required String process,
                Value<String> progress = const Value.absent(),
                required String started,
                required String updated,
                Value<int> rowid = const Value.absent(),
              }) => CareerProcessesCompanion.insert(
                id: id,
                hlc: hlc,
                deleted: deleted,
                name: name,
                template: template,
                profileId: profileId,
                process: process,
                progress: progress,
                started: started,
                updated: updated,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CareerProcessesTable, ProcessRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $CareerProcessesTable,
                    ProcessRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CareerProcessesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CareerProcessesTable,
      ProcessRow,
      $$CareerProcessesTableFilterComposer,
      $$CareerProcessesTableOrderingComposer,
      $$CareerProcessesTableAnnotationComposer,
      $$CareerProcessesTableCreateCompanionBuilder,
      $$CareerProcessesTableUpdateCompanionBuilder,
      (
        ProcessRow,
        BaseReferences<_$AppDatabase, $CareerProcessesTable, ProcessRow>,
      ),
      ProcessRow,
      PrefetchHooks Function()
    >;
typedef $$BridgeStudyPlansTableCreateCompanionBuilder =
    BridgeStudyPlansCompanion Function({
      required String id,
      Value<String> hlc,
      Value<bool> deleted,
      required String source,
      required String plan,
      required String updated,
      Value<int> rowid,
    });
typedef $$BridgeStudyPlansTableUpdateCompanionBuilder =
    BridgeStudyPlansCompanion Function({
      Value<String> id,
      Value<String> hlc,
      Value<bool> deleted,
      Value<String> source,
      Value<String> plan,
      Value<String> updated,
      Value<int> rowid,
    });

class $$BridgeStudyPlansTableFilterComposer
    extends Composer<_$AppDatabase, $BridgeStudyPlansTable> {
  $$BridgeStudyPlansTableFilterComposer({
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

  ColumnFilters<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get plan => $composableBuilder(
    column: $table.plan,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updated => $composableBuilder(
    column: $table.updated,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BridgeStudyPlansTableOrderingComposer
    extends Composer<_$AppDatabase, $BridgeStudyPlansTable> {
  $$BridgeStudyPlansTableOrderingComposer({
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

  ColumnOrderings<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get plan => $composableBuilder(
    column: $table.plan,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updated => $composableBuilder(
    column: $table.updated,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BridgeStudyPlansTableAnnotationComposer
    extends Composer<_$AppDatabase, $BridgeStudyPlansTable> {
  $$BridgeStudyPlansTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get hlc =>
      $composableBuilder(column: $table.hlc, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get plan =>
      $composableBuilder(column: $table.plan, builder: (column) => column);

  GeneratedColumn<String> get updated =>
      $composableBuilder(column: $table.updated, builder: (column) => column);
}

class $$BridgeStudyPlansTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BridgeStudyPlansTable,
          StudyPlan,
          $$BridgeStudyPlansTableFilterComposer,
          $$BridgeStudyPlansTableOrderingComposer,
          $$BridgeStudyPlansTableAnnotationComposer,
          $$BridgeStudyPlansTableCreateCompanionBuilder,
          $$BridgeStudyPlansTableUpdateCompanionBuilder,
          (
            StudyPlan,
            BaseReferences<_$AppDatabase, $BridgeStudyPlansTable, StudyPlan>,
          ),
          StudyPlan,
          PrefetchHooks Function()
        > {
  $$BridgeStudyPlansTableTableManager(
    _$AppDatabase db,
    $BridgeStudyPlansTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BridgeStudyPlansTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BridgeStudyPlansTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BridgeStudyPlansTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> hlc = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String> plan = const Value.absent(),
                Value<String> updated = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BridgeStudyPlansCompanion(
                id: id,
                hlc: hlc,
                deleted: deleted,
                source: source,
                plan: plan,
                updated: updated,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String> hlc = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                required String source,
                required String plan,
                required String updated,
                Value<int> rowid = const Value.absent(),
              }) => BridgeStudyPlansCompanion.insert(
                id: id,
                hlc: hlc,
                deleted: deleted,
                source: source,
                plan: plan,
                updated: updated,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BridgeStudyPlansTable, StudyPlan>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $BridgeStudyPlansTable,
                    StudyPlan
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BridgeStudyPlansTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BridgeStudyPlansTable,
      StudyPlan,
      $$BridgeStudyPlansTableFilterComposer,
      $$BridgeStudyPlansTableOrderingComposer,
      $$BridgeStudyPlansTableAnnotationComposer,
      $$BridgeStudyPlansTableCreateCompanionBuilder,
      $$BridgeStudyPlansTableUpdateCompanionBuilder,
      (
        StudyPlan,
        BaseReferences<_$AppDatabase, $BridgeStudyPlansTable, StudyPlan>,
      ),
      StudyPlan,
      PrefetchHooks Function()
    >;
typedef $$BridgeStudyProgressTableCreateCompanionBuilder =
    BridgeStudyProgressCompanion Function({
      required String id,
      Value<String> hlc,
      Value<bool> deleted,
      Value<String> planUpdated,
      Value<String> progress,
      required String updated,
      Value<int> rowid,
    });
typedef $$BridgeStudyProgressTableUpdateCompanionBuilder =
    BridgeStudyProgressCompanion Function({
      Value<String> id,
      Value<String> hlc,
      Value<bool> deleted,
      Value<String> planUpdated,
      Value<String> progress,
      Value<String> updated,
      Value<int> rowid,
    });

class $$BridgeStudyProgressTableFilterComposer
    extends Composer<_$AppDatabase, $BridgeStudyProgressTable> {
  $$BridgeStudyProgressTableFilterComposer({
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

  ColumnFilters<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get planUpdated => $composableBuilder(
    column: $table.planUpdated,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get progress => $composableBuilder(
    column: $table.progress,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updated => $composableBuilder(
    column: $table.updated,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BridgeStudyProgressTableOrderingComposer
    extends Composer<_$AppDatabase, $BridgeStudyProgressTable> {
  $$BridgeStudyProgressTableOrderingComposer({
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

  ColumnOrderings<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get planUpdated => $composableBuilder(
    column: $table.planUpdated,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get progress => $composableBuilder(
    column: $table.progress,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updated => $composableBuilder(
    column: $table.updated,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BridgeStudyProgressTableAnnotationComposer
    extends Composer<_$AppDatabase, $BridgeStudyProgressTable> {
  $$BridgeStudyProgressTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get hlc =>
      $composableBuilder(column: $table.hlc, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<String> get planUpdated => $composableBuilder(
    column: $table.planUpdated,
    builder: (column) => column,
  );

  GeneratedColumn<String> get progress =>
      $composableBuilder(column: $table.progress, builder: (column) => column);

  GeneratedColumn<String> get updated =>
      $composableBuilder(column: $table.updated, builder: (column) => column);
}

class $$BridgeStudyProgressTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BridgeStudyProgressTable,
          StudyProgressRow,
          $$BridgeStudyProgressTableFilterComposer,
          $$BridgeStudyProgressTableOrderingComposer,
          $$BridgeStudyProgressTableAnnotationComposer,
          $$BridgeStudyProgressTableCreateCompanionBuilder,
          $$BridgeStudyProgressTableUpdateCompanionBuilder,
          (
            StudyProgressRow,
            BaseReferences<
              _$AppDatabase,
              $BridgeStudyProgressTable,
              StudyProgressRow
            >,
          ),
          StudyProgressRow,
          PrefetchHooks Function()
        > {
  $$BridgeStudyProgressTableTableManager(
    _$AppDatabase db,
    $BridgeStudyProgressTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BridgeStudyProgressTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BridgeStudyProgressTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$BridgeStudyProgressTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> hlc = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<String> planUpdated = const Value.absent(),
                Value<String> progress = const Value.absent(),
                Value<String> updated = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BridgeStudyProgressCompanion(
                id: id,
                hlc: hlc,
                deleted: deleted,
                planUpdated: planUpdated,
                progress: progress,
                updated: updated,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String> hlc = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<String> planUpdated = const Value.absent(),
                Value<String> progress = const Value.absent(),
                required String updated,
                Value<int> rowid = const Value.absent(),
              }) => BridgeStudyProgressCompanion.insert(
                id: id,
                hlc: hlc,
                deleted: deleted,
                planUpdated: planUpdated,
                progress: progress,
                updated: updated,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BridgeStudyProgressTable, StudyProgressRow>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $BridgeStudyProgressTable,
                    StudyProgressRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BridgeStudyProgressTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BridgeStudyProgressTable,
      StudyProgressRow,
      $$BridgeStudyProgressTableFilterComposer,
      $$BridgeStudyProgressTableOrderingComposer,
      $$BridgeStudyProgressTableAnnotationComposer,
      $$BridgeStudyProgressTableCreateCompanionBuilder,
      $$BridgeStudyProgressTableUpdateCompanionBuilder,
      (
        StudyProgressRow,
        BaseReferences<
          _$AppDatabase,
          $BridgeStudyProgressTable,
          StudyProgressRow
        >,
      ),
      StudyProgressRow,
      PrefetchHooks Function()
    >;
typedef $$CareerFileDocsTableCreateCompanionBuilder =
    CareerFileDocsCompanion Function({
      required String id,
      Value<String> hlc,
      Value<bool> deleted,
      required String path,
      required String kind,
      required String sha256,
      Value<String> content,
      required String updated,
      Value<String> device,
      Value<int> rowid,
    });
typedef $$CareerFileDocsTableUpdateCompanionBuilder =
    CareerFileDocsCompanion Function({
      Value<String> id,
      Value<String> hlc,
      Value<bool> deleted,
      Value<String> path,
      Value<String> kind,
      Value<String> sha256,
      Value<String> content,
      Value<String> updated,
      Value<String> device,
      Value<int> rowid,
    });

class $$CareerFileDocsTableFilterComposer
    extends Composer<_$AppDatabase, $CareerFileDocsTable> {
  $$CareerFileDocsTableFilterComposer({
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

  ColumnFilters<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sha256 => $composableBuilder(
    column: $table.sha256,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updated => $composableBuilder(
    column: $table.updated,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get device => $composableBuilder(
    column: $table.device,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CareerFileDocsTableOrderingComposer
    extends Composer<_$AppDatabase, $CareerFileDocsTable> {
  $$CareerFileDocsTableOrderingComposer({
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

  ColumnOrderings<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sha256 => $composableBuilder(
    column: $table.sha256,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updated => $composableBuilder(
    column: $table.updated,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get device => $composableBuilder(
    column: $table.device,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CareerFileDocsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CareerFileDocsTable> {
  $$CareerFileDocsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get hlc =>
      $composableBuilder(column: $table.hlc, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<String> get path =>
      $composableBuilder(column: $table.path, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get sha256 =>
      $composableBuilder(column: $table.sha256, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get updated =>
      $composableBuilder(column: $table.updated, builder: (column) => column);

  GeneratedColumn<String> get device =>
      $composableBuilder(column: $table.device, builder: (column) => column);
}

class $$CareerFileDocsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CareerFileDocsTable,
          CareerFileDoc,
          $$CareerFileDocsTableFilterComposer,
          $$CareerFileDocsTableOrderingComposer,
          $$CareerFileDocsTableAnnotationComposer,
          $$CareerFileDocsTableCreateCompanionBuilder,
          $$CareerFileDocsTableUpdateCompanionBuilder,
          (
            CareerFileDoc,
            BaseReferences<_$AppDatabase, $CareerFileDocsTable, CareerFileDoc>,
          ),
          CareerFileDoc,
          PrefetchHooks Function()
        > {
  $$CareerFileDocsTableTableManager(
    _$AppDatabase db,
    $CareerFileDocsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CareerFileDocsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CareerFileDocsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CareerFileDocsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> hlc = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<String> path = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> sha256 = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<String> updated = const Value.absent(),
                Value<String> device = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CareerFileDocsCompanion(
                id: id,
                hlc: hlc,
                deleted: deleted,
                path: path,
                kind: kind,
                sha256: sha256,
                content: content,
                updated: updated,
                device: device,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String> hlc = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                required String path,
                required String kind,
                required String sha256,
                Value<String> content = const Value.absent(),
                required String updated,
                Value<String> device = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CareerFileDocsCompanion.insert(
                id: id,
                hlc: hlc,
                deleted: deleted,
                path: path,
                kind: kind,
                sha256: sha256,
                content: content,
                updated: updated,
                device: device,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CareerFileDocsTable, CareerFileDoc>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $CareerFileDocsTable,
                    CareerFileDoc
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CareerFileDocsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CareerFileDocsTable,
      CareerFileDoc,
      $$CareerFileDocsTableFilterComposer,
      $$CareerFileDocsTableOrderingComposer,
      $$CareerFileDocsTableAnnotationComposer,
      $$CareerFileDocsTableCreateCompanionBuilder,
      $$CareerFileDocsTableUpdateCompanionBuilder,
      (
        CareerFileDoc,
        BaseReferences<_$AppDatabase, $CareerFileDocsTable, CareerFileDoc>,
      ),
      CareerFileDoc,
      PrefetchHooks Function()
    >;
typedef $$CareerSavedSearchesTableCreateCompanionBuilder =
    CareerSavedSearchesCompanion Function({
      required String id,
      Value<String> hlc,
      Value<bool> deleted,
      required String name,
      required String role,
      Value<String> titles,
      Value<bool> exactOnly,
      Value<String> skills,
      Value<String> notWords,
      Value<String> notEmployers,
      Value<String> places,
      Value<String> origin,
      required String created,
      required String updated,
      Value<String?> lastLooked,
      Value<String> seen,
      Value<int> rowid,
    });
typedef $$CareerSavedSearchesTableUpdateCompanionBuilder =
    CareerSavedSearchesCompanion Function({
      Value<String> id,
      Value<String> hlc,
      Value<bool> deleted,
      Value<String> name,
      Value<String> role,
      Value<String> titles,
      Value<bool> exactOnly,
      Value<String> skills,
      Value<String> notWords,
      Value<String> notEmployers,
      Value<String> places,
      Value<String> origin,
      Value<String> created,
      Value<String> updated,
      Value<String?> lastLooked,
      Value<String> seen,
      Value<int> rowid,
    });

class $$CareerSavedSearchesTableFilterComposer
    extends Composer<_$AppDatabase, $CareerSavedSearchesTable> {
  $$CareerSavedSearchesTableFilterComposer({
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

  ColumnFilters<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get titles => $composableBuilder(
    column: $table.titles,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get exactOnly => $composableBuilder(
    column: $table.exactOnly,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get skills => $composableBuilder(
    column: $table.skills,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notWords => $composableBuilder(
    column: $table.notWords,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notEmployers => $composableBuilder(
    column: $table.notEmployers,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get places => $composableBuilder(
    column: $table.places,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get origin => $composableBuilder(
    column: $table.origin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get created => $composableBuilder(
    column: $table.created,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updated => $composableBuilder(
    column: $table.updated,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastLooked => $composableBuilder(
    column: $table.lastLooked,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get seen => $composableBuilder(
    column: $table.seen,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CareerSavedSearchesTableOrderingComposer
    extends Composer<_$AppDatabase, $CareerSavedSearchesTable> {
  $$CareerSavedSearchesTableOrderingComposer({
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

  ColumnOrderings<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get titles => $composableBuilder(
    column: $table.titles,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get exactOnly => $composableBuilder(
    column: $table.exactOnly,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get skills => $composableBuilder(
    column: $table.skills,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notWords => $composableBuilder(
    column: $table.notWords,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notEmployers => $composableBuilder(
    column: $table.notEmployers,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get places => $composableBuilder(
    column: $table.places,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get origin => $composableBuilder(
    column: $table.origin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get created => $composableBuilder(
    column: $table.created,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updated => $composableBuilder(
    column: $table.updated,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastLooked => $composableBuilder(
    column: $table.lastLooked,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get seen => $composableBuilder(
    column: $table.seen,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CareerSavedSearchesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CareerSavedSearchesTable> {
  $$CareerSavedSearchesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get hlc =>
      $composableBuilder(column: $table.hlc, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get titles =>
      $composableBuilder(column: $table.titles, builder: (column) => column);

  GeneratedColumn<bool> get exactOnly =>
      $composableBuilder(column: $table.exactOnly, builder: (column) => column);

  GeneratedColumn<String> get skills =>
      $composableBuilder(column: $table.skills, builder: (column) => column);

  GeneratedColumn<String> get notWords =>
      $composableBuilder(column: $table.notWords, builder: (column) => column);

  GeneratedColumn<String> get notEmployers => $composableBuilder(
    column: $table.notEmployers,
    builder: (column) => column,
  );

  GeneratedColumn<String> get places =>
      $composableBuilder(column: $table.places, builder: (column) => column);

  GeneratedColumn<String> get origin =>
      $composableBuilder(column: $table.origin, builder: (column) => column);

  GeneratedColumn<String> get created =>
      $composableBuilder(column: $table.created, builder: (column) => column);

  GeneratedColumn<String> get updated =>
      $composableBuilder(column: $table.updated, builder: (column) => column);

  GeneratedColumn<String> get lastLooked => $composableBuilder(
    column: $table.lastLooked,
    builder: (column) => column,
  );

  GeneratedColumn<String> get seen =>
      $composableBuilder(column: $table.seen, builder: (column) => column);
}

class $$CareerSavedSearchesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CareerSavedSearchesTable,
          SavedSearchRow,
          $$CareerSavedSearchesTableFilterComposer,
          $$CareerSavedSearchesTableOrderingComposer,
          $$CareerSavedSearchesTableAnnotationComposer,
          $$CareerSavedSearchesTableCreateCompanionBuilder,
          $$CareerSavedSearchesTableUpdateCompanionBuilder,
          (
            SavedSearchRow,
            BaseReferences<
              _$AppDatabase,
              $CareerSavedSearchesTable,
              SavedSearchRow
            >,
          ),
          SavedSearchRow,
          PrefetchHooks Function()
        > {
  $$CareerSavedSearchesTableTableManager(
    _$AppDatabase db,
    $CareerSavedSearchesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CareerSavedSearchesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CareerSavedSearchesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CareerSavedSearchesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> hlc = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> role = const Value.absent(),
                Value<String> titles = const Value.absent(),
                Value<bool> exactOnly = const Value.absent(),
                Value<String> skills = const Value.absent(),
                Value<String> notWords = const Value.absent(),
                Value<String> notEmployers = const Value.absent(),
                Value<String> places = const Value.absent(),
                Value<String> origin = const Value.absent(),
                Value<String> created = const Value.absent(),
                Value<String> updated = const Value.absent(),
                Value<String?> lastLooked = const Value.absent(),
                Value<String> seen = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CareerSavedSearchesCompanion(
                id: id,
                hlc: hlc,
                deleted: deleted,
                name: name,
                role: role,
                titles: titles,
                exactOnly: exactOnly,
                skills: skills,
                notWords: notWords,
                notEmployers: notEmployers,
                places: places,
                origin: origin,
                created: created,
                updated: updated,
                lastLooked: lastLooked,
                seen: seen,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String> hlc = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                required String name,
                required String role,
                Value<String> titles = const Value.absent(),
                Value<bool> exactOnly = const Value.absent(),
                Value<String> skills = const Value.absent(),
                Value<String> notWords = const Value.absent(),
                Value<String> notEmployers = const Value.absent(),
                Value<String> places = const Value.absent(),
                Value<String> origin = const Value.absent(),
                required String created,
                required String updated,
                Value<String?> lastLooked = const Value.absent(),
                Value<String> seen = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CareerSavedSearchesCompanion.insert(
                id: id,
                hlc: hlc,
                deleted: deleted,
                name: name,
                role: role,
                titles: titles,
                exactOnly: exactOnly,
                skills: skills,
                notWords: notWords,
                notEmployers: notEmployers,
                places: places,
                origin: origin,
                created: created,
                updated: updated,
                lastLooked: lastLooked,
                seen: seen,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CareerSavedSearchesTable, SavedSearchRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $CareerSavedSearchesTable,
                    SavedSearchRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CareerSavedSearchesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CareerSavedSearchesTable,
      SavedSearchRow,
      $$CareerSavedSearchesTableFilterComposer,
      $$CareerSavedSearchesTableOrderingComposer,
      $$CareerSavedSearchesTableAnnotationComposer,
      $$CareerSavedSearchesTableCreateCompanionBuilder,
      $$CareerSavedSearchesTableUpdateCompanionBuilder,
      (
        SavedSearchRow,
        BaseReferences<
          _$AppDatabase,
          $CareerSavedSearchesTable,
          SavedSearchRow
        >,
      ),
      SavedSearchRow,
      PrefetchHooks Function()
    >;
typedef $$PrefsTableCreateCompanionBuilder = PrefsCompanion Function({
  required String id,
  Value<String> hlc,
  Value<bool> deleted,
  required String value,
  Value<int> rowid,
});
typedef $$PrefsTableUpdateCompanionBuilder = PrefsCompanion Function({
  Value<String> id,
  Value<String> hlc,
  Value<bool> deleted,
  Value<String> value,
  Value<int> rowid,
});

class $$PrefsTableFilterComposer extends Composer<_$AppDatabase, $PrefsTable> {
  $$PrefsTableFilterComposer({
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

  ColumnFilters<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PrefsTableOrderingComposer
    extends Composer<_$AppDatabase, $PrefsTable> {
  $$PrefsTableOrderingComposer({
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

  ColumnOrderings<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PrefsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PrefsTable> {
  $$PrefsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get hlc =>
      $composableBuilder(column: $table.hlc, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$PrefsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PrefsTable,
          Pref,
          $$PrefsTableFilterComposer,
          $$PrefsTableOrderingComposer,
          $$PrefsTableAnnotationComposer,
          $$PrefsTableCreateCompanionBuilder,
          $$PrefsTableUpdateCompanionBuilder,
          (Pref, BaseReferences<_$AppDatabase, $PrefsTable, Pref>),
          Pref,
          PrefetchHooks Function()
        > {
  $$PrefsTableTableManager(_$AppDatabase db, $PrefsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PrefsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PrefsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PrefsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> hlc = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PrefsCompanion(
                id: id,
                hlc: hlc,
                deleted: deleted,
                value: value,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String> hlc = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => PrefsCompanion.insert(
                id: id,
                hlc: hlc,
                deleted: deleted,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PrefsTable, Pref>(table),
                  BaseReferences<_$AppDatabase, $PrefsTable, Pref>(
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

typedef $$PrefsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PrefsTable,
      Pref,
      $$PrefsTableFilterComposer,
      $$PrefsTableOrderingComposer,
      $$PrefsTableAnnotationComposer,
      $$PrefsTableCreateCompanionBuilder,
      $$PrefsTableUpdateCompanionBuilder,
      (Pref, BaseReferences<_$AppDatabase, $PrefsTable, Pref>),
      Pref,
      PrefetchHooks Function()
    >;
typedef $$OutboxTableCreateCompanionBuilder = OutboxCompanion Function({
  required String entity,
  required String rowId,
  Value<int?> seq,
  Value<int> rowid,
});
typedef $$OutboxTableUpdateCompanionBuilder = OutboxCompanion Function({
  Value<String> entity,
  Value<String> rowId,
  Value<int?> seq,
  Value<int> rowid,
});

class $$OutboxTableFilterComposer
    extends Composer<_$AppDatabase, $OutboxTable> {
  $$OutboxTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get entity => $composableBuilder(
    column: $table.entity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rowId => $composableBuilder(
    column: $table.rowId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OutboxTableOrderingComposer
    extends Composer<_$AppDatabase, $OutboxTable> {
  $$OutboxTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get entity => $composableBuilder(
    column: $table.entity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rowId => $composableBuilder(
    column: $table.rowId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OutboxTableAnnotationComposer
    extends Composer<_$AppDatabase, $OutboxTable> {
  $$OutboxTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get entity =>
      $composableBuilder(column: $table.entity, builder: (column) => column);

  GeneratedColumn<String> get rowId =>
      $composableBuilder(column: $table.rowId, builder: (column) => column);

  GeneratedColumn<int> get seq =>
      $composableBuilder(column: $table.seq, builder: (column) => column);
}

class $$OutboxTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OutboxTable,
          OutboxItem,
          $$OutboxTableFilterComposer,
          $$OutboxTableOrderingComposer,
          $$OutboxTableAnnotationComposer,
          $$OutboxTableCreateCompanionBuilder,
          $$OutboxTableUpdateCompanionBuilder,
          (OutboxItem, BaseReferences<_$AppDatabase, $OutboxTable, OutboxItem>),
          OutboxItem,
          PrefetchHooks Function()
        > {
  $$OutboxTableTableManager(_$AppDatabase db, $OutboxTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OutboxTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OutboxTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OutboxTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> entity = const Value.absent(),
                Value<String> rowId = const Value.absent(),
                Value<int?> seq = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OutboxCompanion(
                entity: entity,
                rowId: rowId,
                seq: seq,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String entity,
                required String rowId,
                Value<int?> seq = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OutboxCompanion.insert(
                entity: entity,
                rowId: rowId,
                seq: seq,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$OutboxTable, OutboxItem>(table),
                  BaseReferences<_$AppDatabase, $OutboxTable, OutboxItem>(
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

typedef $$OutboxTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OutboxTable,
      OutboxItem,
      $$OutboxTableFilterComposer,
      $$OutboxTableOrderingComposer,
      $$OutboxTableAnnotationComposer,
      $$OutboxTableCreateCompanionBuilder,
      $$OutboxTableUpdateCompanionBuilder,
      (OutboxItem, BaseReferences<_$AppDatabase, $OutboxTable, OutboxItem>),
      OutboxItem,
      PrefetchHooks Function()
    >;
typedef $$SyncCursorsTableCreateCompanionBuilder =
    SyncCursorsCompanion Function({
      required String deviceId,
      required int seq,
      Value<int> rowid,
    });
typedef $$SyncCursorsTableUpdateCompanionBuilder =
    SyncCursorsCompanion Function({
      Value<String> deviceId,
      Value<int> seq,
      Value<int> rowid,
    });

class $$SyncCursorsTableFilterComposer
    extends Composer<_$AppDatabase, $SyncCursorsTable> {
  $$SyncCursorsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncCursorsTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncCursorsTable> {
  $$SyncCursorsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncCursorsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncCursorsTable> {
  $$SyncCursorsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<int> get seq =>
      $composableBuilder(column: $table.seq, builder: (column) => column);
}

class $$SyncCursorsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncCursorsTable,
          SyncCursor,
          $$SyncCursorsTableFilterComposer,
          $$SyncCursorsTableOrderingComposer,
          $$SyncCursorsTableAnnotationComposer,
          $$SyncCursorsTableCreateCompanionBuilder,
          $$SyncCursorsTableUpdateCompanionBuilder,
          (
            SyncCursor,
            BaseReferences<_$AppDatabase, $SyncCursorsTable, SyncCursor>,
          ),
          SyncCursor,
          PrefetchHooks Function()
        > {
  $$SyncCursorsTableTableManager(_$AppDatabase db, $SyncCursorsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncCursorsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncCursorsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncCursorsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> deviceId = const Value.absent(),
                Value<int> seq = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncCursorsCompanion(
                deviceId: deviceId,
                seq: seq,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String deviceId,
                required int seq,
                Value<int> rowid = const Value.absent(),
              }) => SyncCursorsCompanion.insert(
                deviceId: deviceId,
                seq: seq,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SyncCursorsTable, SyncCursor>(table),
                  BaseReferences<_$AppDatabase, $SyncCursorsTable, SyncCursor>(
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

typedef $$SyncCursorsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncCursorsTable,
      SyncCursor,
      $$SyncCursorsTableFilterComposer,
      $$SyncCursorsTableOrderingComposer,
      $$SyncCursorsTableAnnotationComposer,
      $$SyncCursorsTableCreateCompanionBuilder,
      $$SyncCursorsTableUpdateCompanionBuilder,
      (
        SyncCursor,
        BaseReferences<_$AppDatabase, $SyncCursorsTable, SyncCursor>,
      ),
      SyncCursor,
      PrefetchHooks Function()
    >;
typedef $$LocalSettingsTableCreateCompanionBuilder =
    LocalSettingsCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$LocalSettingsTableUpdateCompanionBuilder =
    LocalSettingsCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$LocalSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalSettingsTable> {
  $$LocalSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalSettingsTable> {
  $$LocalSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalSettingsTable> {
  $$LocalSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$LocalSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalSettingsTable,
          LocalSetting,
          $$LocalSettingsTableFilterComposer,
          $$LocalSettingsTableOrderingComposer,
          $$LocalSettingsTableAnnotationComposer,
          $$LocalSettingsTableCreateCompanionBuilder,
          $$LocalSettingsTableUpdateCompanionBuilder,
          (
            LocalSetting,
            BaseReferences<_$AppDatabase, $LocalSettingsTable, LocalSetting>,
          ),
          LocalSetting,
          PrefetchHooks Function()
        > {
  $$LocalSettingsTableTableManager(_$AppDatabase db, $LocalSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => LocalSettingsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => LocalSettingsCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalSettingsTable, LocalSetting>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $LocalSettingsTable,
                    LocalSetting
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalSettingsTable,
      LocalSetting,
      $$LocalSettingsTableFilterComposer,
      $$LocalSettingsTableOrderingComposer,
      $$LocalSettingsTableAnnotationComposer,
      $$LocalSettingsTableCreateCompanionBuilder,
      $$LocalSettingsTableUpdateCompanionBuilder,
      (
        LocalSetting,
        BaseReferences<_$AppDatabase, $LocalSettingsTable, LocalSetting>,
      ),
      LocalSetting,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$JobListingsTableTableManager get jobListings =>
      $$JobListingsTableTableManager(_db, _db.jobListings);
  $$JobApplicationsTableTableManager get jobApplications =>
      $$JobApplicationsTableTableManager(_db, _db.jobApplications);
  $$JobEventsTableTableManager get jobEvents =>
      $$JobEventsTableTableManager(_db, _db.jobEvents);
  $$JobChecksTableTableManager get jobChecks =>
      $$JobChecksTableTableManager(_db, _db.jobChecks);
  $$JobArchiveTableTableManager get jobArchive =>
      $$JobArchiveTableTableManager(_db, _db.jobArchive);
  $$CareerContactsTableTableManager get careerContacts =>
      $$CareerContactsTableTableManager(_db, _db.careerContacts);
  $$CareerResumesTableTableManager get careerResumes =>
      $$CareerResumesTableTableManager(_db, _db.careerResumes);
  $$CareerReportsTableTableManager get careerReports =>
      $$CareerReportsTableTableManager(_db, _db.careerReports);
  $$CareerGrowthTableTableManager get careerGrowth =>
      $$CareerGrowthTableTableManager(_db, _db.careerGrowth);
  $$CareerPracticeTableTableManager get careerPractice =>
      $$CareerPracticeTableTableManager(_db, _db.careerPractice);
  $$CareerAnswersTableTableManager get careerAnswers =>
      $$CareerAnswersTableTableManager(_db, _db.careerAnswers);
  $$CareerDocumentsTableTableManager get careerDocuments =>
      $$CareerDocumentsTableTableManager(_db, _db.careerDocuments);
  $$CareerQuestionsTableTableManager get careerQuestions =>
      $$CareerQuestionsTableTableManager(_db, _db.careerQuestions);
  $$CareerJournalTableTableManager get careerJournal =>
      $$CareerJournalTableTableManager(_db, _db.careerJournal);
  $$CareerStoriesTableTableManager get careerStories =>
      $$CareerStoriesTableTableManager(_db, _db.careerStories);
  $$ContactHandlesTableTableManager get contactHandles =>
      $$ContactHandlesTableTableManager(_db, _db.contactHandles);
  $$ConversationsTableTableManager get conversations =>
      $$ConversationsTableTableManager(_db, _db.conversations);
  $$MessagesTableTableManager get messages =>
      $$MessagesTableTableManager(_db, _db.messages);
  $$CareerPostsTableTableManager get careerPosts =>
      $$CareerPostsTableTableManager(_db, _db.careerPosts);
  $$CareerTracksTableTableManager get careerTracks =>
      $$CareerTracksTableTableManager(_db, _db.careerTracks);
  $$CareerRoleProfilesTableTableManager get careerRoleProfiles =>
      $$CareerRoleProfilesTableTableManager(_db, _db.careerRoleProfiles);
  $$CareerProcessesTableTableManager get careerProcesses =>
      $$CareerProcessesTableTableManager(_db, _db.careerProcesses);
  $$BridgeStudyPlansTableTableManager get bridgeStudyPlans =>
      $$BridgeStudyPlansTableTableManager(_db, _db.bridgeStudyPlans);
  $$BridgeStudyProgressTableTableManager get bridgeStudyProgress =>
      $$BridgeStudyProgressTableTableManager(_db, _db.bridgeStudyProgress);
  $$CareerFileDocsTableTableManager get careerFileDocs =>
      $$CareerFileDocsTableTableManager(_db, _db.careerFileDocs);
  $$CareerSavedSearchesTableTableManager get careerSavedSearches =>
      $$CareerSavedSearchesTableTableManager(_db, _db.careerSavedSearches);
  $$PrefsTableTableManager get prefs =>
      $$PrefsTableTableManager(_db, _db.prefs);
  $$OutboxTableTableManager get outbox =>
      $$OutboxTableTableManager(_db, _db.outbox);
  $$SyncCursorsTableTableManager get syncCursors =>
      $$SyncCursorsTableTableManager(_db, _db.syncCursors);
  $$LocalSettingsTableTableManager get localSettings =>
      $$LocalSettingsTableTableManager(_db, _db.localSettings);
}
