Map sortByEntry(Map unsortMap) {
  List list = new LinkedList(unsortMap.entrySet());
  Collections.sort(list, new Comparator() {
    public int compare(Object o1, Object o2) {
      return ((Comparable) ((Map.Entry) (o1)).getValue()).compareTo(((Map.Entry) (o2)).getValue());
    }
  }
  );
  Map sortedMap = new LinkedHashMap();
  for (Iterator it = list.iterator(); it.hasNext();) {
    Map.Entry entry = (Map.Entry) it.next();
    sortedMap.put(entry.getKey(), entry.getValue());
  }
  return sortedMap;
}
