enum PhotoTag {
  cat,
  dog,
  pet,
  selfie,
  groupPhoto,
  child,
  cafe,
  dessert,
  coffee,
  sea,
  mountain,
  sky,
  flower,
  indoor,
  bed,
  receipt,
  document,
}

extension PhotoTagLabel on PhotoTag {
  String get koreanName {
    switch (this) {
      case PhotoTag.cat:
        return '고양이';
      case PhotoTag.dog:
        return '강아지';
      case PhotoTag.pet:
        return '반려동물';
      case PhotoTag.selfie:
        return '셀카';
      case PhotoTag.groupPhoto:
        return '단체사진';
      case PhotoTag.child:
        return '아이';
      case PhotoTag.cafe:
        return '카페';
      case PhotoTag.dessert:
        return '디저트';
      case PhotoTag.coffee:
        return '커피';
      case PhotoTag.sea:
        return '바다';
      case PhotoTag.mountain:
        return '산';
      case PhotoTag.sky:
        return '하늘';
      case PhotoTag.flower:
        return '꽃';
      case PhotoTag.indoor:
        return '실내';
      case PhotoTag.bed:
        return '침대';
      case PhotoTag.receipt:
        return '영수증';
      case PhotoTag.document:
        return '문서';
    }
  }
}
