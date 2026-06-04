import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'auth_service.dart';

class UserAccess {
  final String uid;
  final String role;
  final List<String> childIds;
  final List<String> groupIds;
  final List<String> groupNames;

  const UserAccess({
    required this.uid,
    required this.role,
    this.childIds = const [],
    this.groupIds = const [],
    this.groupNames = const [],
  });

  bool get isAdmin => role == 'admin';
  bool get isTeacher => role == 'teacher';
  bool get isParent => role == 'parent';
  bool get canEditContent => isAdmin || isTeacher;
  bool get canManageUsers => isAdmin;
  bool get canManageChildren => isAdmin;
  bool get canManageGroups => isAdmin;

  bool canViewChild(String childId, Map<String, dynamic> childData) {
    if (isAdmin) return true;

    final parentIds = readStringList(childData['parentIds']);
    if (isParent) {
      return parentIds.contains(uid) || childIds.contains(childId);
    }

    if (isTeacher) {
      final childGroupIds = readStringList(childData['groupIds']);
      final childGroupId = readOptionalString(childData['groupId']);
      final childGroupName = readOptionalString(childData['groupName']);
      final teacherIds = readStringList(childData['teacherIds']);

      return childIds.contains(childId) ||
          teacherIds.contains(uid) ||
          childGroupIds.any(groupIds.contains) ||
          (childGroupId != null && groupIds.contains(childGroupId)) ||
          (childGroupName != null && groupNames.contains(childGroupName));
    }

    return false;
  }

  Query<Map<String, dynamic>> scopeCollection(
    CollectionReference<Map<String, dynamic>> collection, {
    String createdByField = 'createdBy',
  }) {
    if (isAdmin) return collection;

    if (isTeacher) {
      if (groupIds.isNotEmpty) {
        return collection.where(
          'groupIds',
          arrayContainsAny: groupIds.take(30).toList(),
        );
      }
      if (childIds.isNotEmpty) {
        return collection.where(
          'childIds',
          arrayContainsAny: childIds.take(30).toList(),
        );
      }
      return collection.where(createdByField, isEqualTo: uid);
    }

    if (groupIds.isNotEmpty) {
      return collection.where(
        'groupIds',
        arrayContainsAny: groupIds.take(30).toList(),
      );
    }

    if (childIds.isNotEmpty) {
      return collection.where(
        'childIds',
        arrayContainsAny: childIds.take(30).toList(),
      );
    }

    return collection.where('parentIds', arrayContains: uid);
  }

  Map<String, dynamic> contentScopeFields() {
    return {
      'createdBy': uid,
      'teacherIds': isTeacher ? [uid] : <String>[],
      'parentIds': isParent ? [uid] : <String>[],
      'groupIds': groupIds,
      'childIds': childIds,
    };
  }

  static List<String> readStringList(dynamic value) {
    if (value is Iterable) {
      return value
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }

    if (value is String && value.trim().isNotEmpty) {
      return [value.trim()];
    }

    return const [];
  }

  static String? readOptionalString(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }
}

class RoleGuardService {
  RoleGuardService({required this.authService});

  final AuthService authService;

  Future<UserAccess?> loadAccess() async {
    final user = authService.currentUser;
    if (user == null) return null;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final data = doc.data() ?? <String, dynamic>{};
    final rawRole = data['role'];
    final role = rawRole is String ? rawRole.trim().toLowerCase() : 'parent';

    final normalizedRole = switch (role) {
      'admin' || 'teacher' || 'parent' => role,
      _ => 'parent',
    };
    final userChildIds = UserAccess.readStringList(data['childIds']);
    final userGroupIds = [
      ...UserAccess.readStringList(data['groupIds']),
      ...UserAccess.readStringList(data['groupId']),
    ];
    final userGroupNames = [
      ...UserAccess.readStringList(data['groupNames']),
      ...UserAccess.readStringList(data['groupName']),
    ];

    if (normalizedRole == 'parent') {
      final childScope = await _loadParentChildScope(user.uid);
      return UserAccess(
        uid: user.uid,
        role: normalizedRole,
        childIds: mergeStringLists(userChildIds, childScope.childIds),
        groupIds: mergeStringLists(userGroupIds, childScope.groupIds),
        groupNames: mergeStringLists(userGroupNames, childScope.groupNames),
      );
    }

    return UserAccess(
      uid: user.uid,
      role: normalizedRole,
      childIds: userChildIds,
      groupIds: userGroupIds,
      groupNames: userGroupNames,
    );
  }

  Future<_ChildScope> _loadParentChildScope(String uid) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('children')
          .where('parentIds', arrayContains: uid)
          .get();

      final childIds = <String>[];
      final groupIds = <String>[];
      final groupNames = <String>[];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        childIds.add(doc.id);
        groupIds.addAll(UserAccess.readStringList(data['groupIds']));
        groupIds.addAll(UserAccess.readStringList(data['groupId']));
        groupNames.addAll(UserAccess.readStringList(data['groupNames']));
        groupNames.addAll(UserAccess.readStringList(data['groupName']));
      }

      debugPrint(
        'RoleGuardService: parent scope uid=$uid '
        'children=${childIds.length}, childIds=$childIds, groupIds=$groupIds',
      );

      return _ChildScope(
        childIds: childIds,
        groupIds: groupIds,
        groupNames: groupNames,
      );
    } catch (error, stackTrace) {
      if (error is FirebaseException) {
        debugPrint(
          'RoleGuardService: parent scope lookup failed uid=$uid '
          'FirebaseException code=${error.code}, message=${error.message}',
        );
      } else {
        debugPrint(
          'RoleGuardService: parent scope lookup failed uid=$uid: $error',
        );
      }
      debugPrintStack(stackTrace: stackTrace);
      return const _ChildScope();
    }
  }

  List<String> mergeStringLists(List<String> first, List<String> second) {
    return {...first, ...second}.where((item) => item.isNotEmpty).toList();
  }
}

class _ChildScope {
  final List<String> childIds;
  final List<String> groupIds;
  final List<String> groupNames;

  const _ChildScope({
    this.childIds = const [],
    this.groupIds = const [],
    this.groupNames = const [],
  });
}

class RoleGuard extends StatelessWidget {
  final AuthService authService;
  final bool Function(UserAccess access) allowed;
  final Widget Function(BuildContext context, UserAccess access) builder;

  const RoleGuard({
    super.key,
    required this.authService,
    required this.allowed,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserAccess?>(
      future: RoleGuardService(authService: authService).loadAccess(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final access = snapshot.data;
        if (access == null || !allowed(access)) {
          return const AccessDeniedScreen();
        }

        return builder(context, access);
      },
    );
  }
}

class AccessDeniedScreen extends StatelessWidget {
  const AccessDeniedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7ED),
      appBar: AppBar(title: const Text('Kein Zugriff')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 86,
                height: 86,
                decoration: BoxDecoration(
                  color: const Color(0xFFDC2626).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(26),
                ),
                child: const Icon(
                  Icons.lock_rounded,
                  color: Color(0xFFDC2626),
                  size: 46,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Dieser Bereich ist fuer deine Rolle nicht freigegeben.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF334155),
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
