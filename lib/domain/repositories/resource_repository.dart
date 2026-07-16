import 'package:mision_admision/domain/models/resource_card.dart';

abstract interface class ResourceRepository {
  Future<List<ResourceCard>> loadResources();
}
